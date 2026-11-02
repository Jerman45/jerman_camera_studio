# Jerman Camera Studio

Jerman Camera Studio is an Android camera and creative app built with Flutter.
It includes a branded splash and home screen, live photo/video capture,
front/rear camera switching, flash, tap-to-focus, exposure and zoom controls,
and a composition grid.

The app also includes a persistent in-app gallery, photo editor with adjustable
filters and brightness, video preview/editor, saved video projects, profile,
settings, and About pages. Captures are kept in the app gallery and can also be
saved to the device gallery.

Photo filters and brightness adjustments are applied to exported images. Video
projects save edit settings and preview playback; rendered video export, audio
mixing, transitions, split rendering, and some photo tools are not yet
implemented.

## Run on Android

1. Install Flutter and connect an Android phone or start an Android emulator.
2. From the project folder, run `flutter pub get`.
3. Run `flutter run`.
4. Grant camera and microphone access when prompted. Microphone access is used
   for video sound.

Available camera features and quality depend on the Android device. The
viewfinder displays an error and retry option if camera access is unavailable.
