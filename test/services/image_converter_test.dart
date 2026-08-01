import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/frame_data.dart';
import 'package:ghosteye/services/image_converter.dart';

void main() {
  final converter = ImageConverterService();

  test('rejects truncated BGRA planes before indexing raw bytes', () {
    final frame = FrameData(
      width: 2,
      height: 2,
      format: 'bgra8888',
      planes: <FramePlaneData>[
        FramePlaneData(
          bytes: Uint8List.fromList(<int>[0, 0, 0, 255]),
          bytesPerRow: 8,
          bytesPerPixel: 4,
        ),
      ],
    );

    expect(
      () => converter.convertFrameToImageBytes(frame),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects YUV frames without all three planes', () {
    const frame = FrameData(
      width: 2,
      height: 2,
      format: 'yuv420',
      planes: <FramePlaneData>[],
    );

    expect(
      () => converter.convertFrameToImageBytes(frame),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects invalid JPEG configuration', () {
    final frame = FrameData(
      width: 1,
      height: 1,
      format: 'bgra8888',
      planes: <FramePlaneData>[
        FramePlaneData(
          bytes: Uint8List.fromList(<int>[0, 0, 0, 255]),
          bytesPerRow: 4,
          bytesPerPixel: 4,
        ),
      ],
    );

    expect(
      () => converter.convertFrameToImageBytes(frame, jpegQuality: 0),
      throwsA(isA<FormatException>()),
    );
  });
}
