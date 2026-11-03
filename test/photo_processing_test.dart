import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jerman_camera_studio/ai/ai_background_removal_service.dart';
import 'package:jerman_camera_studio/photo_processing.dart';

void main() {
  test('smart enhancement crops, rotates and watermarks an image', () async {
    final directory = await Directory.systemTemp.createTemp('jerman-photo-');
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/source.png');
    final image = img.Image(width: 20, height: 12);
    img.fill(image, color: img.ColorRgb8(90, 120, 150));
    await source.writeAsBytes(img.encodePng(image));

    final result = processPhoto({
      'path': source.path,
      'brightness': 1.0,
      'contrast': 1.0,
      'saturation': 1.0,
      'hue': 0.0,
      'rotation': 1,
      'cropRatio': .8,
      'watermark': true,
      'mode': 'smart',
    });

    final decoded = img.decodeImage(Uint8List.fromList(result));
    expect(decoded, isNotNull);
    expect(decoded!.width, 12);
    expect(decoded.height, 15);
  });

  test('HD mode doubles cropped dimensions and analyzes lighting', () async {
    final directory = await Directory.systemTemp.createTemp('jerman-hd-');
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/source.png');
    final image = img.Image(width: 20, height: 12);
    img.fill(image, color: img.ColorRgb8(90, 120, 150));
    await source.writeAsBytes(img.encodePng(image));

    final settings = {
      'path': source.path,
      'brightness': 1.0,
      'contrast': 1.0,
      'saturation': 1.0,
      'hue': 0.0,
      'rotation': 1,
      'cropRatio': .8,
      'watermark': false,
      'mode': 'hd',
    };
    final analysis = analyzePhoto({'path': source.path});
    final result = processPhoto(settings);
    final decoded = img.decodeImage(Uint8List.fromList(result));

    expect(analysis['width'], 20);
    expect(analysis['height'], 12);
    expect(analysis['averageLuminance'], greaterThan(0));
    expect(analysis['recommendation'], isA<String>());
    expect(decoded!.width, 24);
    expect(decoded.height, 30);
  });

  test('restore and cinematic modes process valid images offline', () async {
    final directory = await Directory.systemTemp.createTemp('jerman-modes-');
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/source.png');
    final image = img.Image(width: 16, height: 16);
    img.fill(image, color: img.ColorRgb8(80, 110, 140));
    await source.writeAsBytes(img.encodePng(image));

    for (final mode in ['restore', 'cinematic']) {
      final result = processPhoto({
        'path': source.path,
        'brightness': 1.0,
        'contrast': 1.0,
        'saturation': 1.0,
        'hue': 0.0,
        'rotation': 0,
        'cropRatio': -1.0,
        'watermark': false,
        'mode': mode,
        'previewMaxDimension': 12,
      });
      final decoded = img.decodeImage(Uint8List.fromList(result));
      expect(decoded!.width, 12);
      expect(decoded.height, 12);
    }
  });

  test(
    'studio portrait mode lifts low light while preserving photo size',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'jerman-portrait-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/source.png');
      final image = img.Image(width: 20, height: 12);
      img.fill(image, color: img.ColorRgb8(40, 42, 44));
      await source.writeAsBytes(img.encodePng(image));

      final result = processPhoto({
        'path': source.path,
        'brightness': 1.0,
        'contrast': 1.0,
        'saturation': 1.0,
        'hue': 0.0,
        'rotation': 0,
        'cropRatio': -1.0,
        'watermark': false,
        'mode': 'studio',
      });
      final decoded = img.decodeImage(Uint8List.fromList(result));

      expect(decoded!.width, 20);
      expect(decoded.height, 12);
      expect(decoded.getPixel(10, 6).r, greaterThan(40));
    },
  );

  test('on-device segmentation mask produces a transparent PNG cutout', () {
    final image = img.Image(width: 2, height: 1, numChannels: 4);
    image.setPixelRgba(0, 0, 255, 0, 0, 255);
    image.setPixelRgba(1, 0, 0, 255, 0, 255);

    final result = applyForegroundMask({
      'sourceBytes': Uint8List.fromList(img.encodePng(image)),
      'maskWidth': 2,
      'maskHeight': 1,
      'confidences': <double>[1.0, 0.0],
    });
    final cutout = img.decodePng(result)!;

    expect(cutout.getPixel(0, 0).a, 255);
    expect(cutout.getPixel(1, 0).a, 0);
  });
}
