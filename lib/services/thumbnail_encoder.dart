import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Produces a small base64-encoded JPEG thumbnail from a larger JPEG frame.
///
/// Runs synchronously and is intended to be called once per completed take,
/// so the decode/resize/encode cost stays off the per-frame hot path.
class ThumbnailEncoder {
  const ThumbnailEncoder({
    this.maxDimension = 160,
    this.quality = 55,
  });

  /// Longest-side length, in pixels, of the generated thumbnail.
  final int maxDimension;

  /// JPEG quality (1-100) of the generated thumbnail.
  final int quality;

  /// Returns a base64-encoded JPEG (no data-URI prefix), or null if
  /// [jpegBytes] is empty or cannot be decoded.
  String? encodeFromJpeg(Uint8List jpegBytes) {
    if (jpegBytes.isEmpty) {
      return null;
    }

    // decodeJpg returns null for some inputs and throws ImageException for
    // others (e.g. a missing Start-Of-Image marker); treat both as "no image".
    final img.Image? decoded;
    try {
      decoded = img.decodeJpg(jpegBytes);
    } catch (_) {
      return null;
    }
    if (decoded == null) {
      return null;
    }

    final longestSide =
        decoded.width >= decoded.height ? decoded.width : decoded.height;
    final img.Image resized;
    if (longestSide <= maxDimension) {
      resized = decoded;
    } else if (decoded.width >= decoded.height) {
      resized = img.copyResize(decoded, width: maxDimension);
    } else {
      resized = img.copyResize(decoded, height: maxDimension);
    }

    final encoded = img.encodeJpg(resized, quality: quality);
    if (encoded.isEmpty) {
      return null;
    }
    return base64Encode(encoded);
  }
}
