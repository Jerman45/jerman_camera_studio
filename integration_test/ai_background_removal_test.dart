import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:jerman_camera_studio/ai/ai_background_removal_service.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const runOnDevice = bool.fromEnvironment('RUN_ML_KIT_DEVICE_TEST');

  testWidgets(
    'ML Kit segments a real photo on device and exports transparency',
    (tester) async {
      final result = await tester.runAsync(() async {
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw StateError('App external storage is not available.');
        }
        final source = File('${directory.path}/ai-segmentation-test.jpg');
        if (!await source.exists()) {
          throw FileSystemException(
            'Push a portrait photo to the app external files directory.',
            source.path,
          );
        }

        try {
          final cutout = await AiBackgroundRemovalService().removeBackground(
            source.path,
          );
          final decoded = img.decodeImage(Uint8List.fromList(cutout));
          if (decoded == null) {
            throw const FormatException('Cutout output is not a valid image.');
          }

          var foregroundPixels = 0;
          var transparentPixels = 0;
          for (var y = 0; y < decoded.height; y += 8) {
            for (var x = 0; x < decoded.width; x += 8) {
              if (decoded.getPixel(x, y).a >= 192) {
                foregroundPixels++;
              } else if (decoded.getPixel(x, y).a < 64) {
                transparentPixels++;
              }
            }
          }
          return (
            width: decoded.width,
            height: decoded.height,
            foregroundPixels: foregroundPixels,
            transparentPixels: transparentPixels,
          );
        } finally {
          if (await source.exists()) await source.delete();
        }
      });

      expect(result, isNotNull);
      expect(result!.width, greaterThan(0));
      expect(result.height, greaterThan(0));
      expect(result.foregroundPixels, greaterThan(0));
      expect(result.transparentPixels, greaterThan(0));
    },
    skip: !runOnDevice,
  );
}
