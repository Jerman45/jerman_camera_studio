import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jerman_camera_studio/photo_processing.dart';

void main() {
  test('photo processing crops, rotates and watermarks an image', () async {
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
      'autoEnhance': true,
    });

    final decoded = img.decodeImage(Uint8List.fromList(result));
    expect(decoded, isNotNull);
    expect(decoded!.width, 12);
    expect(decoded.height, 15);
  });
}
