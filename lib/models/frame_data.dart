import 'dart:typed_data';

import 'package:camera/camera.dart';

class FramePlaneData {
  const FramePlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;

  factory FramePlaneData.fromCameraPlane(Plane plane) {
    // CameraImage plane buffers are not guaranteed to remain valid after the
    // callback returns, so Ghosteye takes an owned copy here before any
    // isolate handoff or deferred processing.
    return FramePlaneData(
      bytes: Uint8List.fromList(plane.bytes),
      bytesPerRow: plane.bytesPerRow,
      bytesPerPixel: plane.bytesPerPixel ?? 1,
    );
  }
}

class FrameData {
  const FrameData({
    required this.width,
    required this.height,
    required this.format,
    required this.planes,
    this.sampledAt,
    this.copyDuration,
  });

  final int width;
  final int height;
  final String format;
  final List<FramePlaneData> planes;
  final DateTime? sampledAt;
  final Duration? copyDuration;

  bool get isBgra8888 => format == 'bgra8888';
  bool get isYuv420 => format == 'yuv420';

  factory FrameData.fromCameraImage(CameraImage image, {DateTime? sampledAt}) {
    final stopwatch = Stopwatch()..start();
    final copiedPlanes = image.planes
        .map(FramePlaneData.fromCameraPlane)
        .toList(growable: false);
    stopwatch.stop();

    return FrameData(
      width: image.width,
      height: image.height,
      format: image.format.group.name,
      planes: copiedPlanes,
      sampledAt: sampledAt ?? DateTime.now().toUtc(),
      copyDuration: stopwatch.elapsed,
    );
  }
}
