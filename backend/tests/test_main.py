import io
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient
from PIL import Image

import main


def png_bytes(color: tuple[int, int, int] = (20, 80, 160)) -> bytes:
    output = io.BytesIO()
    Image.new("RGB", (8, 8), color).save(output, format="PNG")
    return output.getvalue()


@pytest.fixture
def client(monkeypatch: pytest.MonkeyPatch) -> TestClient:
    vertex_client_factory = main._vertex_client
    vertex_client_factory.cache_clear()
    monkeypatch.setattr(main, "_authenticate", lambda _: "test-user")
    with TestClient(main.app) as test_client:
        yield test_client
    vertex_client_factory.cache_clear()


def test_health_check_is_available_without_authentication() -> None:
    with TestClient(main.app) as client:
        response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_image_edit_returns_generated_image(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    result = png_bytes((12, 34, 56))
    model_response = SimpleNamespace(
        candidates=[
            SimpleNamespace(
                content=SimpleNamespace(
                    parts=[
                        SimpleNamespace(
                            inline_data=SimpleNamespace(
                                data=result,
                                mime_type="image/png",
                            )
                        )
                    ]
                )
            )
        ]
    )
    def generate_content(**kwargs):
        assert kwargs["model"] == "gemini-3.1-flash-image"
        assert "Replace the background with a studio." in kwargs["contents"][1]
        assert main.Modality.IMAGE in kwargs["config"].response_modalities
        return model_response

    fake_vertex = SimpleNamespace(
        models=SimpleNamespace(
            generate_content=generate_content,
        )
    )
    monkeypatch.setattr(main, "_vertex_client", lambda: fake_vertex)

    response = client.post(
        "/v1/images/edit",
        headers={"Authorization": "Bearer test-token"},
        files={"image": ("source.png", png_bytes(), "image/png")},
        data={"instruction": "Replace the background with a studio."},
    )

    assert response.status_code == 200
    assert response.headers["content-type"] == "image/png"
    assert response.headers["cache-control"] == "no-store"
    assert response.content == result


def test_authentication_is_required() -> None:
    with TestClient(main.app) as client:
        response = client.post("/v1/images/edit")
    assert response.status_code == 401


def test_firebase_token_is_verified_and_revocation_checked(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    firebase_app = object()
    verification: dict[str, object] = {}

    def verify_id_token(token: str, app: object, check_revoked: bool) -> dict[str, str]:
        verification.update(token=token, app=app, check_revoked=check_revoked)
        return {"uid": "verified-user"}

    monkeypatch.setattr(main, "_firebase_app", lambda: firebase_app)
    monkeypatch.setattr(main.auth, "verify_id_token", verify_id_token)

    assert main._authenticate("Bearer valid-token") == "verified-user"
    assert verification == {
        "token": "valid-token",
        "app": firebase_app,
        "check_revoked": True,
    }


def test_rejects_mime_type_mismatch(client: TestClient) -> None:
    response = client.post(
        "/v1/images/edit",
        headers={"Authorization": "Bearer test-token"},
        files={"image": ("source.jpg", png_bytes(), "image/jpeg")},
        data={"instruction": "Make the colors warmer."},
    )
    assert response.status_code == 415


def test_rejects_oversized_image(client: TestClient) -> None:
    response = client.post(
        "/v1/images/edit",
        headers={"Authorization": "Bearer test-token"},
        files={
            "image": (
                "source.png",
                b"x" * (main.MAX_IMAGE_BYTES + 1),
                "image/png",
            )
        },
        data={"instruction": "Make the colors warmer."},
    )
    assert response.status_code == 413


def test_rejects_missing_image_from_model(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    fake_vertex = SimpleNamespace(
        models=SimpleNamespace(
            generate_content=lambda **_: SimpleNamespace(candidates=[]),
        )
    )
    monkeypatch.setattr(main, "_vertex_client", lambda: fake_vertex)

    response = client.post(
        "/v1/images/edit",
        headers={"Authorization": "Bearer test-token"},
        files={"image": ("source.png", png_bytes(), "image/png")},
        data={"instruction": "Make the colors warmer."},
    )
    assert response.status_code == 422


def test_rejects_invalid_image_returned_by_model(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    fake_vertex = SimpleNamespace(
        models=SimpleNamespace(
            generate_content=lambda **_: SimpleNamespace(
                candidates=[
                    SimpleNamespace(
                        content=SimpleNamespace(
                            parts=[
                                SimpleNamespace(
                                    inline_data=SimpleNamespace(
                                        data=b"not an image",
                                        mime_type="image/png",
                                    )
                                )
                            ]
                        )
                    )
                ]
            ),
        )
    )
    monkeypatch.setattr(main, "_vertex_client", lambda: fake_vertex)

    response = client.post(
        "/v1/images/edit",
        headers={"Authorization": "Bearer test-token"},
        files={"image": ("source.png", png_bytes(), "image/png")},
        data={"instruction": "Make the colors warmer."},
    )
    assert response.status_code == 502
