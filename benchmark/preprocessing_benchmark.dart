// Directional host-side benchmark comparing the Dart and FFI frame
// preprocessing paths (colour convert + JPEG encode).
//
// This file lives outside `test/` so it is NOT part of the default `flutter
// test` / CI suite. Run it explicitly:
//
//   dart run tool/compile_ffi.dart   # (or let setUpAll compile it)
//   flutter test benchmark/preprocessing_benchmark.dart
//
// Numbers are indicative only. They are measured on the host CPU (typically
// x64), not on a target mobile device, so treat them as a relative signal
// about whether the native path is worth its complexity — not as an absolute
// on-device figure.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/frame_data.dart';
import 'package:ghosteye/services/image_converter.dart';
import 'package:ghosteye_frame_ffi/ghosteye_frame_ffi.dart';

const _maxDimension = 768;
const _quality = 88;
const _warmup = 3;
const _iterations = 25;

FrameData _bgraFrame(int width, int height) {
  final bytes = Uint8List(width * height * 4);
  for (var i = 0; i < bytes.length; i += 4) {
    bytes[i] = i % 256; // B
    bytes[i + 1] = (i ~/ 4) % 256; // G
    bytes[i + 2] = (i ~/ 16) % 256; // R
    bytes[i + 3] = 255; // A
  }
  return FrameData(
    width: width,
    height: height,
    format: 'bgra8888',
    planes: <FramePlaneData>[
      FramePlaneData(bytes: bytes, bytesPerRow: width * 4, bytesPerPixel: 4),
    ],
  );
}

FrameData _yuvFrame(int width, int height) {
  final y = Uint8List(width * height);
  for (var i = 0; i < y.length; i++) {
    y[i] = i % 256;
  }
  final chromaWidth = width ~/ 2;
  final chromaHeight = height ~/ 2;
  final u = Uint8List(chromaWidth * chromaHeight);
  final v = Uint8List(chromaWidth * chromaHeight);
  for (var i = 0; i < u.length; i++) {
    u[i] = (i * 3) % 256;
    v[i] = (i * 5) % 256;
  }
  return FrameData(
    width: width,
    height: height,
    format: 'yuv420',
    planes: <FramePlaneData>[
      FramePlaneData(bytes: y, bytesPerRow: width, bytesPerPixel: 1),
      FramePlaneData(bytes: u, bytesPerRow: chromaWidth, bytesPerPixel: 1),
      FramePlaneData(bytes: v, bytesPerRow: chromaWidth, bytesPerPixel: 1),
    ],
  );
}

Duration _median(List<Duration> samples) {
  final sorted = List<Duration>.from(samples)
    ..sort((a, b) => a.compareTo(b));
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid];
  }
  return Duration(
    microseconds:
        ((sorted[mid - 1].inMicroseconds + sorted[mid].inMicroseconds) / 2)
            .round(),
  );
}

double _medianMillis(int Function() run) {
  for (var i = 0; i < _warmup; i++) {
    run();
  }
  final samples = <Duration>[];
  for (var i = 0; i < _iterations; i++) {
    final sw = Stopwatch()..start();
    final produced = run();
    sw.stop();
    if (produced <= 0) {
      throw StateError('Benchmark run produced an empty buffer.');
    }
    samples.add(sw.elapsed);
  }
  return _median(samples).inMicroseconds / 1000.0;
}

void main() {
  String? ffiLibraryPath;

  setUpAll(() {
    if (!Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    final libraryFile = File(
      '${Directory.systemTemp.path}/ghosteye_frame_ffi_benchmark'
      '${Platform.isMacOS ? '.dylib' : '.so'}',
    );
    const source = 'packages/ghosteye_frame_ffi/src/ghosteye_frame_ffi.c';
    final args = Platform.isMacOS
        ? <String>['-dynamiclib', '-O2', '-std=c11', '-o', libraryFile.path, source]
        : <String>[
            '-shared',
            '-fPIC',
            '-O2',
            '-std=c11',
            '-o',
            libraryFile.path,
            source,
            '-lm',
          ];
    final result = Process.runSync('cc', args);
    if (result.exitCode != 0) {
      throw StateError('Failed to compile FFI library: ${result.stderr}');
    }
    ffiLibraryPath = libraryFile.path;
  });

  test('Dart vs FFI preprocessing (host, directional)', () {
    if (ffiLibraryPath == null) {
      stdout.writeln('Skipped: no C compiler / unsupported platform.');
      return;
    }

    final codec = ImageConverterService();
    final ffi = GhosteyeFrameFfi(libraryPath: ffiLibraryPath);

    const sizes = <List<int>>[
      <int>[1280, 720],
      <int>[1920, 1080],
    ];

    stdout.writeln('');
    stdout.writeln('=== Preprocessing benchmark (host, median of '
        '$_iterations runs, ms) ===');
    stdout.writeln('format   size        dart      ffi     speedup');

    for (final size in sizes) {
      final width = size[0];
      final height = size[1];

      final bgra = _bgraFrame(width, height);
      final dartBgra = _medianMillis(
        () => codec
            .convertFrameToImageBytes(
              bgra,
              maxDimension: _maxDimension,
              jpegQuality: _quality,
            )
            .length,
      );
      final ffiBgra = _medianMillis(
        () => ffi
            .convertBgra8888ToJpeg(
              bytes: bgra.planes.first.bytes,
              width: width,
              height: height,
              bytesPerRow: bgra.planes.first.bytesPerRow,
              maxDimension: _maxDimension,
              quality: _quality,
            )
            .length,
      );

      final yuv = _yuvFrame(width, height);
      final dartYuv = _medianMillis(
        () => codec
            .convertFrameToImageBytes(
              yuv,
              maxDimension: _maxDimension,
              jpegQuality: _quality,
            )
            .length,
      );
      final ffiYuv = _medianMillis(
        () => ffi
            .convertYuv420ToJpeg(
              yPlane: yuv.planes[0].bytes,
              yBytesPerRow: yuv.planes[0].bytesPerRow,
              uPlane: yuv.planes[1].bytes,
              uBytesPerRow: yuv.planes[1].bytesPerRow,
              uBytesPerPixel: yuv.planes[1].bytesPerPixel,
              vPlane: yuv.planes[2].bytes,
              vBytesPerRow: yuv.planes[2].bytesPerRow,
              vBytesPerPixel: yuv.planes[2].bytesPerPixel,
              width: width,
              height: height,
              maxDimension: _maxDimension,
              quality: _quality,
            )
            .length,
      );

      final sizeLabel = '${width}x$height';
      stdout.writeln('bgra8888 ${sizeLabel.padRight(11)} '
          '${dartBgra.toStringAsFixed(2).padLeft(7)} '
          '${ffiBgra.toStringAsFixed(2).padLeft(7)} '
          '${(dartBgra / ffiBgra).toStringAsFixed(2).padLeft(7)}x');
      stdout.writeln('yuv420   ${sizeLabel.padRight(11)} '
          '${dartYuv.toStringAsFixed(2).padLeft(7)} '
          '${ffiYuv.toStringAsFixed(2).padLeft(7)} '
          '${(dartYuv / ffiYuv).toStringAsFixed(2).padLeft(7)}x');
    }
    stdout.writeln('');

    // The benchmark passes as long as both paths produced JPEGs above.
    expect(ffiLibraryPath, isNotNull);
  });
}
