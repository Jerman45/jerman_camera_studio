import io
import logging
import os
from functools import lru_cache

import firebase_admin
from fastapi import FastAPI, HTTPException, Request, Response
from firebase_admin import auth
from firebase_admin.exceptions import FirebaseError
from google import genai
from google.genai.errors import APIError
from google.genai.types import GenerateContentConfig, Modality
from PIL import Image, UnidentifiedImageError
from starlette.concurrency import run_in_threadpool
from starlette.datastructures import UploadFile
from starlette.formparsers import MultiPartException

logger = logging.getLogger("jerman_camera_studio.ai")

MAX_IMAGE_BYTES = 6 * 1024 * 1024
MAX_REQUEST_BYTES = MAX_IMAGE_BYTES + 128 * 1024
MAX_IMAGE_PIXELS = 24_000_000
MAX_INSTRUCTION_LENGTH = 1000
MAX_OUTPUT_BYTES = 12 * 1024 * 1024

SUPPORTED_MIME_TYPES = {
    "image/jpeg": "JPEG",
    "image/png": "PNG",
    "image/webp": "WEBP",
}

app = FastAPI(title="Jerman Camera Studio AI", docs_url=None, redoc_url=None)


@lru_cache(maxsize=1)
def _vertex_client() -> genai.Client:
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
    location = os.environ.get("GOOGLE_CLOUD_LOCATION")
    if not project_id or not location:
        raise HTTPException(
            status_code=503,
            detail="Cloud image editing is not configured.",
        )
    return genai.Client(vertexai=True, project=project_id, location=location)


def _firebase_app() -> firebase_admin.App:
    project_id = os.environ.get("FIREBASE_PROJECT_ID")
    if not project_id:
        raise HTTPException(
            status_code=503,
            detail="Firebase authentication is not configured.",
        )
    try:
        return firebase_admin.get_app("jerman-camera-studio")
    except ValueError:
        return firebase_admin.initialize_app(
            options={"projectId": project_id},
            name="jerman-camera-studio",
        )


def _authenticate(authorization: str | None) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="A Firebase ID token is required.")

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(status_code=401, detail="A Firebase ID token is required.")

    try:
        claims = auth.verify_id_token(
            token,
            app=_firebase_app(),
            check_revoked=True,
        )
    except (
        ValueError,
        auth.InvalidIdTokenError,
        auth.ExpiredIdTokenError,
        auth.RevokedIdTokenError,
        auth.UserDisabledError,
        auth.UserNotFoundError,
    ) as error:
        raise HTTPException(status_code=401, detail="The Firebase ID token is invalid.") from error
    except FirebaseError as error:
        logger.warning("Firebase token verification is unavailable (%s).", type(error).__name__)
        raise HTTPException(
            status_code=503,
            detail="Firebase authentication could not verify the token.",
        ) from error

    user_id = claims.get("uid")
    if not isinstance(user_id, str) or not user_id:
        raise HTTPException(status_code=401, detail="The Firebase ID token is invalid.")
    return user_id


def _decode_image(image_bytes: bytes, declared_mime_type: str) -> Image.Image:
    expected_format = SUPPORTED_MIME_TYPES.get(declared_mime_type)
    if expected_format is None:
        raise HTTPException(
            status_code=415,
            detail="Use a JPEG, PNG, or WebP image.",
        )

    try:
        with Image.open(io.BytesIO(image_bytes)) as image:
            if image.format != expected_format:
                raise HTTPException(
                    status_code=415,
                    detail="The uploaded image does not match its declared file type.",
                )
            if image.width * image.height > MAX_IMAGE_PIXELS:
                raise HTTPException(
                    status_code=413,
                    detail="The image dimensions are too large.",
                )
            image.verify()

        with Image.open(io.BytesIO(image_bytes)) as image:
            image.load()
            return image.copy()
    except UnidentifiedImageError as error:
        raise HTTPException(status_code=400, detail="The uploaded file is not a valid image.") from error
    except Image.DecompressionBombError as error:
        raise HTTPException(status_code=413, detail="The image dimensions are too large.") from error
    except OSError as error:
        raise HTTPException(status_code=400, detail="The uploaded image could not be decoded.") from error


def _generated_image(response: object) -> tuple[bytes, str]:
    candidates = getattr(response, "candidates", None) or []
    for candidate in candidates:
        content = getattr(candidate, "content", None)
        for part in getattr(content, "parts", None) or []:
            inline_data = getattr(part, "inline_data", None)
            image_bytes = getattr(inline_data, "data", None)
            mime_type = getattr(inline_data, "mime_type", None)
            if not isinstance(image_bytes, bytes) or mime_type not in SUPPORTED_MIME_TYPES:
                continue
            if len(image_bytes) > MAX_OUTPUT_BYTES:
                raise HTTPException(status_code=502, detail="The edited image exceeded the output limit.")
            try:
                _decode_image(image_bytes, mime_type)
            except HTTPException as error:
                raise HTTPException(
                    status_code=502,
                    detail="The editing service returned invalid image data.",
                ) from error
            return image_bytes, mime_type

    raise HTTPException(
        status_code=422,
        detail="The model did not return an edited image for this request.",
    )


@app.get("/healthz")
def health_check() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/images/edit")
async def edit_image(request: Request) -> Response:
    _authenticate(request.headers.get("authorization"))

    content_length = request.headers.get("content-length")
    if content_length:
        try:
            request_size = int(content_length)
        except ValueError as error:
            raise HTTPException(status_code=400, detail="Invalid Content-Length header.") from error
        if request_size > MAX_REQUEST_BYTES:
            raise HTTPException(status_code=413, detail="The request is too large.")

    try:
        form = await request.form(max_files=1, max_fields=1)
    except MultiPartException as error:
        logger.info("Rejected malformed multipart image-edit request.")
        raise HTTPException(status_code=400, detail="The multipart request is invalid.") from error

    if set(form.keys()) != {"image", "instruction"}:
        raise HTTPException(
            status_code=400,
            detail="Provide exactly one image and one instruction.",
        )

    upload = form.get("image")
    instruction = form.get("instruction")
    if not isinstance(upload, UploadFile) or not isinstance(instruction, str):
        raise HTTPException(
            status_code=400,
            detail="Provide an image file and a text instruction.",
        )

    instruction = instruction.strip()
    if not instruction or len(instruction) > MAX_INSTRUCTION_LENGTH:
        raise HTTPException(
            status_code=400,
            detail=f"The instruction must be between 1 and {MAX_INSTRUCTION_LENGTH} characters.",
        )

    try:
        image_bytes = await upload.read(MAX_IMAGE_BYTES + 1)
    finally:
        await upload.close()

    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="The image file is too large.")

    image = _decode_image(image_bytes, upload.content_type or "")
    prompt = (
        "Edit this image according to the user's instruction. "
        "Preserve the subject's identity and natural appearance unless requested otherwise. "
        "User instruction: "
        f"{instruction}"
    )

    try:
        model_response = await run_in_threadpool(
            _vertex_client().models.generate_content,
            model="gemini-3.1-flash-image",
            contents=[image, prompt],
            config=GenerateContentConfig(
                response_modalities=[Modality.TEXT, Modality.IMAGE],
            ),
        )
    except APIError as error:
        logger.warning("Vertex AI image editing request failed (status=%s).", error.code)
        raise HTTPException(
            status_code=429 if error.code == 429 else 502,
            detail=(
                "The image editing service is temporarily busy."
                if error.code == 429
                else "The image editing service could not complete the request."
            ),
        ) from error

    edited_bytes, mime_type = _generated_image(model_response)
    extension = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}[mime_type]
    return Response(
        content=edited_bytes,
        media_type=mime_type,
        headers={
            "Cache-Control": "no-store",
            "Content-Disposition": f'attachment; filename="edited-image.{extension}"',
            "X-Content-Type-Options": "nosniff",
        },
    )
