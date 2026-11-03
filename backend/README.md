# Jerman Camera Studio AI backend

This is an un-deployed Cloud Run service for one cloud feature: editing an
uploaded photo from a text instruction using Vertex AI
(`gemini-3.1-flash-image`). It is separate from the Flutter app until Firebase
Authentication is configured in the app.

## Security and data handling

- Every edit request must include `Authorization: Bearer <Firebase ID token>`.
  The service verifies the token with Firebase Admin, checks revocation, and
  requires a Firebase project ID.
- The runtime uses Application Default Credentials (ADC); no API key or service
  account key is stored in this repository or shipped to Android.
- Requests accept one JPEG, PNG, or WebP image up to 6 MiB and one instruction
  up to 1,000 characters. Decoded images are limited to 24 megapixels.
- The service does not save uploaded or generated images. It returns the edited
  image directly with `Cache-Control: no-store`; Vertex AI processes the image
  according to the selected Google Cloud service's terms and data controls.
- The app must keep the original locally and let the user preview/save the
  returned image. Do not upload a photo without the user's explicit action.
- Add per-user quotas and abuse monitoring before public release. Cloud Run
  instance limits can cap overall concurrency but do not replace user quotas.

## Run tests locally

Use Python 3.12, then from this directory run:

```powershell
python -m pip install -r requirements-dev.txt
python -m pytest
```

Tests replace Firebase and Vertex AI boundaries with fakes; they do not need
cloud credentials or incur model charges.

## Prepare a local server

Create a Firebase project and configure Firebase Authentication in the Android
app before connecting it to this service. The Flutter app currently has no
Firebase sign-in flow, so there is intentionally no cloud-edit button yet.

For local development, set `FIREBASE_PROJECT_ID`, `GOOGLE_CLOUD_PROJECT`, and
`GOOGLE_CLOUD_LOCATION`, set `GOOGLE_GENAI_USE_ENTERPRISE=True`, and configure
Application Default Credentials using `gcloud auth application-default login`.
Never put credentials in this folder.
Then run:

```powershell
python -m uvicorn main:app --reload --port 8080
```

The `gemini-3.1-flash-image` model call requires an enabled Google Cloud project,
Vertex AI access, and billing. No inference is made by the automated tests.

## Cloud Run deployment (not performed)

Deployment is deliberately not automatic. Before deploying, configure a runtime
service account with only the required Vertex AI permissions
(`roles/aiplatform.user`), enable the Vertex AI API, set up Firebase
Authentication, review model data processing terms, and configure quotas and
monitoring. Set `FIREBASE_PROJECT_ID` to the project that issues the app's ID
tokens. The Cloud Run service uses ADC for Vertex AI; do not create or upload
service-account keys.

Example command, after reviewing cost/security settings and replacing
`PROJECT_ID` and `RUNTIME_SERVICE_ACCOUNT`:

```powershell
gcloud run deploy jerman-camera-studio-ai `
  --source backend `
  --project PROJECT_ID `
  --region us-central1 `
  --service-account RUNTIME_SERVICE_ACCOUNT `
  --set-env-vars FIREBASE_PROJECT_ID=PROJECT_ID,GOOGLE_CLOUD_PROJECT=PROJECT_ID,GOOGLE_CLOUD_LOCATION=global,GOOGLE_GENAI_USE_ENTERPRISE=True `
  --memory 1Gi `
  --cpu 1 `
  --concurrency 1 `
  --max 2 `
  --timeout 120 `
  --allow-unauthenticated
```

Cloud Run's unauthenticated transport access is required for direct mobile
clients; authorization is enforced by Firebase ID-token verification in the
service. Do not rely on the service URL being secret. Add application-level
rate limits before enabling the endpoint for users. Deployment, project setup,
and billing have not been performed.

## API

`POST /v1/images/edit` accepts multipart form fields `image` and `instruction`,
and requires a Firebase bearer ID token. On success it returns the edited image
bytes using the generated image's MIME type. `GET /healthz` is an unauthenticated
liveness check and does not indicate that Firebase or Vertex AI is configured.
