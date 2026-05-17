import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/frame_data.dart';
import 'package:ghosteye/models/frame_preprocessor_settings.dart';
import 'package:ghosteye/services/frame_preprocessor.dart';
import 'package:ghosteye_frame_ffi/ghosteye_frame_ffi.dart';
import 'package:image/image.dart' as img;

FrameData _buildBgraFrame() {
  return FrameData(
    width: 2,
    height: 1,
    format: 'bgra8888',
    planes: <FramePlaneData>[
      FramePlaneData(
        bytes: Uint8List.fromList(<int>[
          0,
          0,
          255,
          255,
          0,
          255,
          0,
          255,
        ]),
        bytesPerRow: 8,
        bytesPerPixel: 4,
      ),
    ],
  );
}

FrameData _buildYuvFrame() {
  return FrameData(
    width: 2,
    height: 2,
    format: 'yuv420',
    planes: <FramePlaneData>[
      FramePlaneData(
        bytes: Uint8List.fromList(<int>[120, 120, 120, 120]),
        bytesPerRow: 2,
        bytesPerPixel: 1,
      ),
      FramePlaneData(
        bytes: Uint8List.fromList(<int>[128]),
        bytesPerRow: 1,
        bytesPerPixel: 1,
      ),
      FramePlaneData(
        bytes: Uint8List.fromList(<int>[128]),
        bytesPerRow: 1,
        bytesPerPixel: 1,
      ),
    ],
  );
}

FramePreprocessor _buildPreprocessor(
  FramePreprocessorBackend backend, {
  String? ffiLibraryPath,
}) {
  return FramePreprocessor.worker(
    settings: FramePreprocessorSettings(
      backend: backend,
      maxDimension: 2,
      jpegQuality: 88,
    ),
    ffiLibraryPath: ffiLibraryPath,
  );
}

void _expectSimilarPixels(img.Image actual, img.Image expected) {
  expect(actual.width, expected.width);
  expect(actual.height, expected.height);

  for (var y = 0; y < actual.height; y++) {
    for (var x = 0; x < actual.width; x++) {
      final actualPixel = actual.getPixel(x, y);
      final expectedPixel = expected.getPixel(x, y);
      expect((actualPixel.r - expectedPixel.r).abs(), lessThanOrEqualTo(20));
      expect((actualPixel.g - expectedPixel.g).abs(), lessThanOrEqualTo(20));
      expect((actualPixel.b - expectedPixel.b).abs(), lessThanOrEqualTo(20));
    }
  }
}

Future<img.Image> _decode(
    FramePreprocessor preprocessor, FrameData frame) async {
  final processed = await preprocessor.preprocess(frame);
  final decoded = img.decodeJpg(processed.imageBytes);
  expect(decoded, isNotNull);
  return decoded!;
}

void main() {
  String? ffiLibraryPath;

  setUpAll(() {
    if (!Platform.isMacOS) {
      return;
    }

    final dylib = File(
      '${Directory.systemTemp.path}/ghosteye_frame_ffi_test.dylib',
    );
    final result = Process.runSync(
      'cc',
      <String>[
        '-dynamiclib',
        '-O2',
        '-std=c11',
        '-o',
        dylib.path,
        'packages/ghosteye_frame_ffi/src/ghosteye_frame_ffi.c',
      ],
    );

    if (result.exitCode != 0) {
      throw StateError(
        'Failed to compile ghosteye_frame_ffi test dylib: ${result.stderr}',
      );
    }

    ffiLibraryPath = dylib.path;
  });

  test('FramePreprocessor converts BGRA frames with the Dart backend',
      () async {
    final preprocessor = _buildPreprocessor(FramePreprocessorBackend.dart);
    addTearDown(preprocessor.dispose);

    final decoded = await _decode(preprocessor, _buildBgraFrame());

    expect(decoded.width, 2);
    expect(decoded.height, 1);
  });

  test('FramePreprocessor converts YUV420 frames with the Dart backend',
      () async {
    final preprocessor = _buildPreprocessor(FramePreprocessorBackend.dart);
    addTearDown(preprocessor.dispose);

    final decoded = await _decode(preprocessor, _buildYuvFrame());

    expect(decoded.width, 2);
    expect(decoded.height, 2);
  });

  test('FramePreprocessor converts BGRA frames with the FFI backend', () async {
    final preprocessor = _buildPreprocessor(
      FramePreprocessorBackend.ffi,
      ffiLibraryPath: ffiLibraryPath,
    );
    addTearDown(preprocessor.dispose);

    final decoded = await _decode(preprocessor, _buildBgraFrame());

    expect(decoded.width, 2);
    expect(decoded.height, 1);
  });

  test('FramePreprocessor converts YUV420 frames with the FFI backend',
      () async {
    final preprocessor = _buildPreprocessor(
      FramePreprocessorBackend.ffi,
      ffiLibraryPath: ffiLibraryPath,
    );
    addTearDown(preprocessor.dispose);

    final decoded = await _decode(preprocessor, _buildYuvFrame());

    expect(decoded.width, 2);
    expect(decoded.height, 2);
  });

  test('FramePreprocessor keeps Dart and FFI output visually aligned',
      () async {
    final dartPreprocessor = _buildPreprocessor(FramePreprocessorBackend.dart);
    final ffiPreprocessor = _buildPreprocessor(
      FramePreprocessorBackend.ffi,
      ffiLibraryPath: ffiLibraryPath,
    );
    addTearDown(dartPreprocessor.dispose);
    addTearDown(ffiPreprocessor.dispose);

    final dartImage = await _decode(dartPreprocessor, _buildYuvFrame());
    final ffiImage = await _decode(ffiPreprocessor, _buildYuvFrame());

    _expectSimilarPixels(ffiImage, dartImage);
  });

  test('FramePreprocessor surfaces unsupported formats from the worker',
      () async {
    final preprocessor = _buildPreprocessor(FramePreprocessorBackend.dart);
    addTearDown(preprocessor.dispose);

    const frame = FrameData(
      width: 1,
      height: 1,
      format: 'unsupported',
      planes: <FramePlaneData>[],
    );

    await expectLater(
      preprocessor.preprocess(frame),
      throwsA(isA<StateError>()),
    );
  });

  test('FramePreprocessor cancels pending requests during shutdown', () async {
    final preprocessor = FramePreprocessor.worker(
      settings: const FramePreprocessorSettings(
        backend: FramePreprocessorBackend.dart,
        maxDimension: 2,
        jpegQuality: 88,
      ),
      workerDelay: const Duration(milliseconds: 200),
    );

    final future = preprocessor.preprocess(_buildYuvFrame());
    await preprocessor.dispose();

    await expectLater(future, throwsA(isA<StateError>()));
  });

  test('FFI preprocessing frees native buffers after each conversion',
      () async {
    final ffi = GhosteyeFrameFfi(libraryPath: ffiLibraryPath);
    final preprocessor = _buildPreprocessor(
      FramePreprocessorBackend.ffi,
      ffiLibraryPath: ffiLibraryPath,
    );
    addTearDown(preprocessor.dispose);

    expect(ffi.activeAllocationCount, 0);
    await preprocessor.preprocess(_buildBgraFrame());
    expect(ffi.activeAllocationCount, 0);
  });

  group('GhosteyeFrameFfi native JPEG encoding', () {
    test(
        'convertBgra8888ToJpeg returns a decodable JPEG with correct dimensions',
        () {
      if (ffiLibraryPath == null) return;

      final ffi = GhosteyeFrameFfi(libraryPath: ffiLibraryPath);
      final frame = _buildBgraFrame();
      final jpegBytes = ffi.convertBgra8888ToJpeg(
        bytes: frame.planes.first.bytes,
        width: frame.width,
        height: frame.height,
        bytesPerRow: frame.planes.first.bytesPerRow,
        maxDimension: 768,
        quality: 88,
      );

      final decoded = img.decodeJpg(jpegBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(frame.width));
      expect(decoded.height, equals(frame.height));
      expect(ffi.activeAllocationCount, equals(0));
    });

    test('convertYuv420ToJpeg returns a decodable JPEG with correct dimensions',
        () {
      if (ffiLibraryPath == null) return;

      final ffi = GhosteyeFrameFfi(libraryPath: ffiLibraryPath);
      final frame = _buildYuvFrame();
      final jpegBytes = ffi.convertYuv420ToJpeg(
        yPlane: frame.planes[0].bytes,
        yBytesPerRow: frame.planes[0].bytesPerRow,
        uPlane: frame.planes[1].bytes,
        uBytesPerRow: frame.planes[1].bytesPerRow,
        uBytesPerPixel: frame.planes[1].bytesPerPixel,
        vPlane: frame.planes[2].bytes,
        vBytesPerRow: frame.planes[2].bytesPerRow,
        vBytesPerPixel: frame.planes[2].bytesPerPixel,
        width: frame.width,
        height: frame.height,
        maxDimension: 768,
        quality: 88,
      );

      final decoded = img.decodeJpg(jpegBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(frame.width));
      expect(decoded.height, equals(frame.height));
      expect(ffi.activeAllocationCount, equals(0));
    });

    test('native BGRA conversion is byte-aligned before JPEG encoding', () {
      if (ffiLibraryPath == null) return;

      final ffi = GhosteyeFrameFfi(libraryPath: ffiLibraryPath);
      final frame = _buildBgraFrame();
      final rgb = ffi.convertBgra8888ToRgb(
        bytes: frame.planes.first.bytes,
        width: frame.width,
        height: frame.height,
        bytesPerRow: frame.planes.first.bytesPerRow,
        maxDimension: 2,
      );

      expect(rgb.width, equals(frame.width));
      expect(rgb.height, equals(frame.height));
      expect(
        rgb.bytes,
        equals(<int>[
          255,
          0,
          0,
          0,
          255,
          0,
        ]),
      );
      expect(ffi.activeAllocationCount, equals(0));
    });
  });
}
