import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const int _maximumUpscalePixels = 24000000;

Map<String, Object> analyzePhoto(Map<String, Object> settings) {
  final path = settings['path']! as String;
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) {
    throw const FormatException('Unsupported or invalid photo.');
  }
  final image = img.bakeOrientation(decoded);
  final stepX = (image.width / 96).ceil().clamp(1, image.width);
  final stepY = (image.height / 96).ceil().clamp(1, image.height);
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var shadows = 0;
  var highlights = 0;
  var samples = 0;

  for (var y = 0; y < image.height; y += stepY) {
    for (var x = 0; x < image.width; x += stepX) {
      final pixel = image.getPixel(x, y);
      red += pixel.r;
      green += pixel.g;
      blue += pixel.b;
      final luminance = _luminance(pixel.r, pixel.g, pixel.b);
      if (luminance < 48) shadows++;
      if (luminance > 220) highlights++;
      samples++;
    }
  }

  final averageLuminance = _luminance(
    red / samples,
    green / samples,
    blue / samples,
  );
  final shadowPercent = shadows / samples;
  final highlightPercent = highlights / samples;
  final recommendation =
      averageLuminance < 95 || shadowPercent > .3 || highlightPercent > .3
      ? 'smart'
      : 'cinematic';

  return {
    'width': image.width,
    'height': image.height,
    'averageLuminance': averageLuminance,
    'shadowPercent': shadowPercent,
    'highlightPercent': highlightPercent,
    'recommendation': recommendation,
  };
}

Uint8List processPhoto(Map<String, Object> settings) {
  final path = settings['path']! as String;
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) {
    throw const FormatException('Unsupported or invalid photo.');
  }

  var output = img.bakeOrientation(decoded);
  final mode = settings['mode']! as String;
  var brightness = settings['brightness']! as double;
  var contrast = settings['contrast']! as double;
  var saturation = settings['saturation']! as double;
  final stats = _sampleImage(output);

  switch (mode) {
    case 'smart':
      final gamma = stats.averageLuminance < 112
          ? .86
          : stats.averageLuminance > 178
          ? 1.1
          : 1.0;
      output = img.gamma(output, gamma: gamma);
      _applySubtleWhiteBalance(output, stats);
      brightness *= (128 / stats.averageLuminance).clamp(.88, 1.12);
      contrast *= 1.06;
      saturation *= 1.03;
    case 'restore':
      output = img.gaussianBlur(output, radius: 1);
      output = img.convolution(
        output,
        filter: [0, -.25, 0, -.25, 2, -.25, 0, -.25, 0],
        amount: .55,
      );
      contrast *= 1.04;
    case 'cinematic':
      contrast *= 1.14;
      saturation *= .88;
    case 'hd':
      break;
    default:
      throw ArgumentError.value(mode, 'mode', 'Unknown graphics mode.');
  }

  output = img.adjustColor(
    output,
    brightness: brightness,
    contrast: contrast,
    saturation: saturation,
    hue: settings['hue']! as double,
  );

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

  final previewMaxDimension = settings['previewMaxDimension'] as int?;
  if (mode == 'hd' && previewMaxDimension == null) {
    final targetPixels = output.width * output.height * 4;
    final scale = targetPixels <= _maximumUpscalePixels
        ? 2.0
        : math.sqrt(_maximumUpscalePixels / (output.width * output.height));
    output = img.copyResize(
      output,
      width: (output.width * scale).round(),
      height: (output.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );
  }

  if (previewMaxDimension != null &&
      (output.width > previewMaxDimension ||
          output.height > previewMaxDimension)) {
    output = img.copyResize(
      output,
      width: output.width >= output.height ? previewMaxDimension : null,
      height: output.height > output.width ? previewMaxDimension : null,
      interpolation: img.Interpolation.average,
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

_ImageStats _sampleImage(img.Image image) {
  final stepX = (image.width / 64).ceil().clamp(1, image.width);
  final stepY = (image.height / 64).ceil().clamp(1, image.height);
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var samples = 0;
  for (var y = 0; y < image.height; y += stepY) {
    for (var x = 0; x < image.width; x += stepX) {
      final pixel = image.getPixel(x, y);
      red += pixel.r;
      green += pixel.g;
      blue += pixel.b;
      samples++;
    }
  }
  red /= samples;
  green /= samples;
  blue /= samples;
  return _ImageStats(_luminance(red, green, blue), red, green, blue);
}

void _applySubtleWhiteBalance(img.Image image, _ImageStats stats) {
  final target =
      (stats.averageRed + stats.averageGreen + stats.averageBlue) / 3;
  double gain(double average) => average <= 0
      ? 1
      : math.pow(target / average, .25).clamp(.96, 1.04).toDouble();
  final redGain = gain(stats.averageRed);
  final greenGain = gain(stats.averageGreen);
  final blueGain = gain(stats.averageBlue);
  for (final pixel in image) {
    pixel
      ..r = (pixel.r * redGain).clamp(0, 255)
      ..g = (pixel.g * greenGain).clamp(0, 255)
      ..b = (pixel.b * blueGain).clamp(0, 255);
  }
}

double _luminance(num red, num green, num blue) =>
    .2126 * red + .7152 * green + .0722 * blue;

class _ImageStats {
  const _ImageStats(
    this.averageLuminance,
    this.averageRed,
    this.averageGreen,
    this.averageBlue,
  );

  final double averageLuminance;
  final double averageRed;
  final double averageGreen;
  final double averageBlue;
}
