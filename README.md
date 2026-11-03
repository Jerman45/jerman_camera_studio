# Jerman Camera Studio

Jerman Camera Studio is an Android camera and creative app built with Flutter.
It includes a branded splash and home screen, live photo/video capture,
front/rear camera switching, flash, tap-to-focus, exposure and zoom controls,
and a composition grid.

The app also includes a persistent in-app gallery, media import, saved video
projects, profile, settings, and About pages. Camera settings control capture
quality, video frame rate, the composition grid, optional photo watermarking,
and optional on-device auto enhancement.

The photo editor analyzes image dimensions and lighting, then offers Smart
Enhance, Studio Portrait, HD Upscale, Restore, and Cinematic modes, plus
brightness/contrast/saturation controls, crop ratios, rotation, before/after
comparison, optional watermarking, reset, and gallery export. Studio Portrait
gently lifts shadows, protects highlights and sharpens globally; it does not
detect faces or create studio lighting. HD Upscale uses cubic resampling up to
2× (with an output memory limit); Restore uses conventional denoising and
sharpening. These are offline image-processing effects, not AI inference, and
cannot reconstruct missing details. The Android photo editor includes real
on-device subject segmentation through Google's ML Kit for transparent PNG
background removal. The model runs locally; source photos are not uploaded.
Text-prompt background generation, AI super-resolution, face-aware portrait
retouching, and AI effects are not implemented.

The photo camera also has an optional full-body portrait framing guide to help
keep subjects within the frame; it is a composition aid, not person detection.

The Android video editor can trim and split clips into MP4 exports using
keyframe-aligned native media processing, then save them to the app and device
galleries. Playback speed, music, titles, and transitions are project settings
and are not rendered into the exported video. Object removal, audio mixing, and
rendered titles/transitions are not implemented. Cloud AI features (including
video enhancement, editing assistant, and captions) require a configured,
secured backend and are not yet available.

To run the ML Kit integration check on an Android device, place a portrait test
photo at
`/sdcard/Android/data/com.example.jerman_camera_studio/files/ai-segmentation-test.jpg`,
then run
`flutter test integration_test/ai_background_removal_test.dart -d <device-id> --dart-define=RUN_ML_KIT_DEVICE_TEST=true`.
The integration test deletes its temporary device-side test copy when it
finishes.

## Run on Android

1. Install Flutter and connect an Android phone or start an Android emulator.
2. From the project folder, run `flutter pub get`.
3. Run `flutter run`.
4. Grant camera and microphone access when prompted. Microphone access is used
   for video sound.

Available camera features and quality depend on the Android device. The
viewfinder displays an error and retry option if camera access is unavailable.
