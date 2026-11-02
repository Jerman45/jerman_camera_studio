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
Enhance, HD Upscale, Restore, and Cinematic modes, plus brightness/contrast/
saturation controls, crop ratios, rotation, before/after comparison, optional
watermarking, reset, and gallery export. HD Upscale uses cubic resampling up to
2× (with an output memory limit); Restore uses conventional denoising and
sharpening. These are offline image-processing effects, not AI inference, and
cannot reconstruct missing details. No AI model is bundled. AI portrait
segmentation, background effects, and AI super-resolution are not implemented.

The Android video editor can trim and split clips into MP4 exports using
keyframe-aligned native media processing, then save them to the app and device
galleries. Playback speed, music, titles, and transitions are project settings
and are not rendered into the exported video. Object removal, audio mixing, and
rendered titles/transitions are not implemented.

## Run on Android

1. Install Flutter and connect an Android phone or start an Android emulator.
2. From the project folder, run `flutter pub get`.
3. Run `flutter run`.
4. Grant camera and microphone access when prompted. Microphone access is used
   for video sound.

Available camera features and quality depend on the Android device. The
viewfinder displays an error and retry option if camera access is unavailable.
