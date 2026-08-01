import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/services/thumbnail_encoder.dart';
import 'package:image/image.dart' as img;

Uint8List _makeJpeg(int width, int height) {
  final image = img.Image(width: width, height: height);
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  const encoder = ThumbnailEncoder(maxDimension: 160, quality: 55);

  test('downscales a large JPEG to the max dimension, preserving aspect', () {
    final result = encoder.encodeFromJpeg(_makeJpeg(640, 480));

    expect(result, isNotNull);
    final decoded = img.decodeJpg(base64Decode(result!));
    expect(decoded, isNotNull);
    expect(decoded!.width, equals(160));
    expect(decoded.height, equals(120));
  });

  test('clamps the longest side when the source is portrait', () {
    final result = encoder.encodeFromJpeg(_makeJpeg(480, 640));

    final decoded = img.decodeJpg(base64Decode(result!))!;
    expect(decoded.height, equals(160));
    expect(decoded.width, equals(120));
  });

  test('does not upscale a source already within the max dimension', () {
    final result = encoder.encodeFromJpeg(_makeJpeg(80, 100));

    final decoded = img.decodeJpg(base64Decode(result!))!;
    expect(decoded.width, equals(80));
    expect(decoded.height, equals(100));
  });

  test('returns null for empty input', () {
    expect(encoder.encodeFromJpeg(Uint8List(0)), isNull);
  });

  test('returns null for non-decodable input', () {
    expect(
      encoder.encodeFromJpeg(Uint8List.fromList(<int>[9, 8, 7, 6, 5])),
      isNull,
    );
  });
}
