# Jerman Camera Studio

Jerman Camera Studio is a Flutter camera app for Android with a live camera
viewfinder, photo capture, video recording, front/rear camera switching, flash,
tap-to-focus, exposure and zoom controls, and a composition grid. Captures are
saved to the device gallery.

## Run on Android

1. Install Flutter and connect an Android phone or start an Android emulator.
2. From the project folder, run `flutter pub get`.
3. Run `flutter run`.
4. Grant camera and microphone access when prompted. Microphone access is used
   for video sound.

Available camera features and quality depend on the Android device. The
viewfinder displays an error and retry option if camera access is unavailable.
