import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;

class AiBackgroundRemovalService {
  Future<Uint8List> removeBackground(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException(
        'The selected photo could not be found.',
        sourcePath,
      );
    }

    final segmenter = SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );
    try {
      final mask = await segmenter.processImage(
        InputImage.fromFilePath(sourcePath),
      );
      if (mask == null) {
        throw StateError('The on-device segmentation model returned no mask.');
      }
      if (mask.width <= 0 ||
          mask.height <= 0 ||
          mask.confidences.length != mask.width * mask.height) {
        throw const FormatException(
          'The segmentation model returned an invalid mask.',
        );
      }

      final bytes = await source.readAsBytes();
      return await compute<Map<String, Object>, Uint8List>(
        applyForegroundMask,
        {
          'sourceBytes': bytes,
          'maskWidth': mask.width,
          'maskHeight': mask.height,
          'confidences': mask.confidences,
        },
      );
    } finally {
      await segmenter.close();
    }
  }
}

Uint8List applyForegroundMask(Map<String, Object> input) {
  final sourceBytes = input['sourceBytes']! as Uint8List;
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw const FormatException('Unsupported or invalid photo.');
  }
  final image = img.bakeOrientation(source);
  final maskWidth = input['maskWidth']! as int;
  final maskHeight = input['maskHeight']! as int;
  final confidences = input['confidences']! as List<double>;
  if (maskWidth <= 0 ||
      maskHeight <= 0 ||
      confidences.length != maskWidth * maskHeight) {
    throw const FormatException('The segmentation mask is incomplete.');
  }

  for (var y = 0; y < image.height; y++) {
    final maskY = ((y + .5) * maskHeight / image.height - .5)
        .clamp(0, maskHeight - 1)
        .toDouble();
    final y0 = maskY.floor();
    final y1 = (y0 + 1).clamp(0, maskHeight - 1).toInt();
    final fy = maskY - y0;
    for (var x = 0; x < image.width; x++) {
      final maskX = ((x + .5) * maskWidth / image.width - .5)
          .clamp(0, maskWidth - 1)
          .toDouble();
      final x0 = maskX.floor();
      final x1 = (x0 + 1).clamp(0, maskWidth - 1).toInt();
      final fx = maskX - x0;
      final topLeft = confidences[y0 * maskWidth + x0];
      final topRight = confidences[y0 * maskWidth + x1];
      final bottomLeft = confidences[y1 * maskWidth + x0];
      final bottomRight = confidences[y1 * maskWidth + x1];
      final top = topLeft + (topRight - topLeft) * fx;
      final bottom = bottomLeft + (bottomRight - bottomLeft) * fx;
      final confidence = (top + (bottom - top) * fy).clamp(0.0, 1.0);
      final pixel = image.getPixel(x, y);
      image.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, pixel.a * confidence);
    }
  }

  return Uint8List.fromList(img.encodePng(image, level: 6));
}
