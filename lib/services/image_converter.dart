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
    _validateFrame(frame, maxDimension: maxDimension, jpegQuality: jpegQuality);
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

    final uPixelStride = uPlane.bytesPerPixel == 0 ? 1 : uPlane.bytesPerPixel;
    final vPixelStride = vPlane.bytesPerPixel == 0 ? 1 : vPlane.bytesPerPixel;

    for (var y = 0; y < outputHeight; y++) {
      final srcY = math.min(frame.height - 1, (y * scale).floor());
      final uvRow = srcY ~/ 2;
      for (var x = 0; x < outputWidth; x++) {
        final srcX = math.min(frame.width - 1, (x * scale).floor());
        final uvCol = srcX ~/ 2;

        final yValue = yPlane.bytes[srcY * yPlane.bytesPerRow + srcX];
        final uIndex = uvRow * uPlane.bytesPerRow + uvCol * uPixelStride;
        final vIndex = uvRow * vPlane.bytesPerRow + uvCol * vPixelStride;
        final uValue = uPlane.bytes[uIndex];
        final vValue = vPlane.bytes[vIndex];

        final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final g = (yValue -
                0.344136 * (uValue - 128) -
                0.714136 * (vValue - 128))
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

  static void _validateFrame(
    FrameData frame, {
    required int maxDimension,
    required int jpegQuality,
  }) {
    if (frame.width <= 0 || frame.height <= 0) {
      throw const FormatException('Camera frame dimensions must be positive.');
    }
    if (maxDimension <= 0) {
      throw const FormatException('Image maxDimension must be positive.');
    }
    if (jpegQuality < 1 || jpegQuality > 100) {
      throw const FormatException('JPEG quality must be between 1 and 100.');
    }

    switch (frame.format) {
      case 'bgra8888':
        if (frame.planes.isEmpty) {
          throw const FormatException('BGRA frames require one image plane.');
        }
        final plane = frame.planes.first;
        _validatePlane(
          plane,
          lastByteIndex:
              (frame.height - 1) * plane.bytesPerRow +
              (frame.width - 1) * 4 +
              3,
          label: 'BGRA',
        );
      case 'yuv420':
        if (frame.planes.length < 3) {
          throw const FormatException('YUV420 frames require three planes.');
        }
        final yPlane = frame.planes[0];
        final uPlane = frame.planes[1];
        final vPlane = frame.planes[2];
        _validatePlane(
          yPlane,
          lastByteIndex:
              (frame.height - 1) * yPlane.bytesPerRow + frame.width - 1,
          label: 'Y',
        );
        final chromaWidth = (frame.width + 1) ~/ 2;
        final chromaHeight = (frame.height + 1) ~/ 2;
        _validatePlane(
          uPlane,
          lastByteIndex:
              (chromaHeight - 1) * uPlane.bytesPerRow +
              (chromaWidth - 1) *
                  (uPlane.bytesPerPixel == 0 ? 1 : uPlane.bytesPerPixel),
          label: 'U',
        );
        _validatePlane(
          vPlane,
          lastByteIndex:
              (chromaHeight - 1) * vPlane.bytesPerRow +
              (chromaWidth - 1) *
                  (vPlane.bytesPerPixel == 0 ? 1 : vPlane.bytesPerPixel),
          label: 'V',
        );
      default:
        return;
    }
  }

  static void _validatePlane(
    FramePlaneData plane, {
    required int lastByteIndex,
    required String label,
  }) {
    if (plane.bytesPerRow <= 0 ||
        lastByteIndex < 0 ||
        plane.bytes.length <= lastByteIndex) {
      throw FormatException('$label camera plane is truncated or malformed.');
    }
  }
}
