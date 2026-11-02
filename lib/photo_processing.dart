import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List processPhoto(Map<String, Object> settings) {
  final path = settings['path']! as String;
  final original = img.decodeImage(File(path).readAsBytesSync());
  if (original == null) {
    throw const FormatException('Unsupported or invalid photo.');
  }

  var output = img.bakeOrientation(original);
  final autoEnhance = settings['autoEnhance']! as bool;
  var brightness = settings['brightness']! as double;
  var contrast = settings['contrast']! as double;
  var saturation = settings['saturation']! as double;

  if (autoEnhance) {
    var luminance = 0.0;
    var samples = 0;
    final strideX = (output.width / 64).ceil().clamp(1, output.width);
    final strideY = (output.height / 64).ceil().clamp(1, output.height);
    for (var y = 0; y < output.height; y += strideY) {
      for (var x = 0; x < output.width; x += strideX) {
        final pixel = output.getPixel(x, y);
        luminance += .2126 * pixel.r + .7152 * pixel.g + .0722 * pixel.b;
        samples++;
      }
    }
    final averageLuminance = luminance / samples;
    brightness *= (128 / averageLuminance).clamp(.82, 1.2);
    contrast *= 1.08;
    saturation *= 1.04;
  }

  output = img.adjustColor(
    output,
    brightness: brightness,
    contrast: contrast,
    saturation: saturation,
    hue: settings['hue']! as double,
  );
  if (autoEnhance) {
    output = img.convolution(
      output,
      filter: [0, -.25, 0, -.25, 2, -.25, 0, -.25, 0],
      amount: .2,
    );
  }

  final turns = settings['rotation']! as int;
  if (turns != 0) output = img.copyRotate(output, angle: turns * 90);

  final cropRatio = settings['cropRatio']! as double;
  if (cropRatio > 0) {
    final width = output.width;
    final height = output.height;
    final currentRatio = width / height;
    final cropWidth = currentRatio > cropRatio
        ? (height * cropRatio).round()
        : width;
    final cropHeight = currentRatio > cropRatio
        ? height
        : (width / cropRatio).round();
    output = img.copyCrop(
      output,
      x: (width - cropWidth) ~/ 2,
      y: (height - cropHeight) ~/ 2,
      width: cropWidth,
      height: cropHeight,
    );
  }

  if (settings['watermark']! as bool) {
    img.drawString(
      output,
      'JERMAN TECHNOLOGY',
      font: img.arial14,
      x: (output.width - 170).clamp(0, output.width).toInt(),
      y: (output.height - 22).clamp(0, output.height).toInt(),
      color: img.ColorRgba8(255, 255, 255, 210),
    );
  }

  return Uint8List.fromList(img.encodeJpg(output, quality: 94));
}
