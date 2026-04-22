import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../config/constants.dart';
import '../models/frame_data.dart';

class ImageConverterService {
  Uint8List convertFrameToImageBytes(
    FrameData frame, {
    int maxDimension = AppConstants.modelInputMaxDimension,
    int jpegQuality = AppConstants.frameJpegQuality,
  }) {
    final image = switch (frame.format) {
      'bgra8888' => _convertBgra(frame, maxDimension),
      'yuv420' => _convertYuv420(frame, maxDimension),
      _ => throw UnsupportedError('Unsupported camera format: ${frame.format}'),
    };

    return Uint8List.fromList(img.encodeJpg(image, quality: jpegQuality));
  }

  Uint8List encodeRgbToImageBytes({
    required Uint8List rgbBytes,
    required int width,
    required int height,
    int jpegQuality = AppConstants.frameJpegQuality,
  }) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      bytesOffset: rgbBytes.offsetInBytes,
      rowStride: width * 3,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: jpegQuality));
  }

  static img.Image _convertBgra(FrameData frame, int maxDimension) {
    final plane = frame.planes.first;
    final scale = _scaleFor(frame.width, frame.height, maxDimension);
    final outputWidth = math.max(1, (frame.width / scale).round());
    final outputHeight = math.max(1, (frame.height / scale).round());
    final image = img.Image(width: outputWidth, height: outputHeight);

    for (var y = 0; y < outputHeight; y++) {
      final srcY = math.min(frame.height - 1, (y * scale).floor());
      for (var x = 0; x < outputWidth; x++) {
        final srcX = math.min(frame.width - 1, (x * scale).floor());
        final offset = srcY * plane.bytesPerRow + srcX * 4;
        final b = plane.bytes[offset];
        final g = plane.bytes[offset + 1];
        final r = plane.bytes[offset + 2];
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  static img.Image _convertYuv420(FrameData frame, int maxDimension) {
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];

    final scale = _scaleFor(frame.width, frame.height, maxDimension);
    final outputWidth = math.max(1, (frame.width / scale).round());
    final outputHeight = math.max(1, (frame.height / scale).round());
    final image = img.Image(width: outputWidth, height: outputHeight);

    final uvPixelStride = uPlane.bytesPerPixel == 0 ? 1 : uPlane.bytesPerPixel;

    for (var y = 0; y < outputHeight; y++) {
      final srcY = math.min(frame.height - 1, (y * scale).floor());
      final uvRow = srcY ~/ 2;
      for (var x = 0; x < outputWidth; x++) {
        final srcX = math.min(frame.width - 1, (x * scale).floor());
        final uvCol = srcX ~/ 2;

        final yValue = yPlane.bytes[srcY * yPlane.bytesPerRow + srcX];
        final uvIndex = uvRow * uPlane.bytesPerRow + uvCol * uvPixelStride;
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  static double _scaleFor(int width, int height, int maxDimension) {
    final longestSide = math.max(width, height).toDouble();
    if (longestSide <= maxDimension) {
      return 1;
    }
    return longestSide / maxDimension;
  }
}
