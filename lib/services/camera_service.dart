import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';

import '../config/constants.dart';
import '../models/frame_data.dart';

typedef NowProvider = DateTime Function();

enum CameraFailureKind {
  permissionDenied,
  permissionDeniedPermanently,
  restricted,
  unavailable,
  unknown,
}

class CameraFailure implements Exception {
  const CameraFailure({
    required this.kind,
    required this.message,
    this.details,
  });

  final CameraFailureKind kind;
  final String message;
  final Object? details;

  bool get canOpenSettings =>
      kind == CameraFailureKind.permissionDeniedPermanently;

  bool get canRetry => kind != CameraFailureKind.restricted;

  String get title => switch (kind) {
        CameraFailureKind.permissionDenied => 'Grant Camera Access',
        CameraFailureKind.permissionDeniedPermanently => 'Camera Access Needed',
        CameraFailureKind.restricted => 'Camera Access Restricted',
        CameraFailureKind.unavailable => 'Camera Unavailable',
        CameraFailureKind.unknown => 'Camera Error',
      };

  String get guidance => switch (kind) {
        CameraFailureKind.permissionDenied =>
          'Ghosteye needs camera access to turn the live shot into screenplay text. Grant access, then retry.',
        CameraFailureKind.permissionDeniedPermanently =>
          'Camera access was denied earlier. Open Settings and enable Camera for Ghosteye, then return and retry.',
        CameraFailureKind.restricted =>
          'This device is restricting camera access, so Ghosteye cannot start the live director view right now.',
        CameraFailureKind.unavailable =>
          'Ghosteye could not find a usable camera on this device. Check device availability and retry.',
        CameraFailureKind.unknown =>
          'Ghosteye could not start the camera. Retry once, then check device permissions if it keeps failing.',
      };

  @override
  String toString() => message;
}

CameraFailure classifyCameraFailure(Object error) {
  if (error is CameraFailure) {
    return error;
  }

  if (error is CameraException) {
    return switch (error.code) {
      'CameraAccessDenied' => CameraFailure(
          kind: CameraFailureKind.permissionDenied,
          message: error.description ?? 'Camera access was denied.',
          details: error,
        ),
      'CameraAccessDeniedWithoutPrompt' => CameraFailure(
          kind: CameraFailureKind.permissionDeniedPermanently,
          message: error.description ??
              'Camera access was previously denied and cannot be requested again from inside the app.',
          details: error,
        ),
      'CameraAccessRestricted' => CameraFailure(
          kind: CameraFailureKind.restricted,
          message: error.description ?? 'Camera access is restricted.',
          details: error,
        ),
      _ => CameraFailure(
          kind: CameraFailureKind.unknown,
          message: error.description ?? error.code,
          details: error,
        ),
    };
  }

  if (error is StateError && error.message.contains('No cameras')) {
    return CameraFailure(
      kind: CameraFailureKind.unavailable,
      message: error.message,
      details: error,
    );
  }

  return CameraFailure(
    kind: CameraFailureKind.unknown,
    message: error.toString(),
    details: error,
  );
}

class FrameSampler {
  FrameSampler({
    required this.interval,
    NowProvider? now,
  }) : _now = now ?? DateTime.now;

  Duration interval;
  final NowProvider _now;
  DateTime _lastSampled = DateTime.fromMillisecondsSinceEpoch(0);
  bool inferenceInProgress = false;

  bool shouldSample() {
    if (inferenceInProgress) {
      return false;
    }

    final now = _now();
    if (now.difference(_lastSampled) < interval) {
      return false;
    }

    _lastSampled = now;
    inferenceInProgress = true;
    return true;
  }

  void markInferenceComplete() {
    inferenceInProgress = false;
  }

  void updateInterval(Duration value) {
    interval = value;
  }
}

class CameraSession {
  const CameraSession({
    required this.controller,
    required this.sampledFrames,
    required this.sampler,
    required this.sampleInterval,
  });

  final CameraController controller;
  final Stream<FrameData> sampledFrames;
  final FrameSampler sampler;
  final Duration sampleInterval;

  CameraSession copyWith({
    Duration? sampleInterval,
  }) {
    return CameraSession(
      controller: controller,
      sampledFrames: sampledFrames,
      sampler: sampler,
      sampleInterval: sampleInterval ?? this.sampleInterval,
    );
  }
}

class CameraService {
  StreamController<FrameData>? _sampledFramesController;

  Future<CameraSession> initialize({
    Duration interval = AppConstants.frameSampleInterval,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No cameras are available on this device.');
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      final sampler = FrameSampler(interval: interval);
      final streamController = StreamController<FrameData>.broadcast();
      _sampledFramesController = streamController;

      await controller.startImageStream((CameraImage image) {
        if (!sampler.shouldSample()) {
          return;
        }

        try {
          streamController.add(FrameData.fromCameraImage(image));
        } catch (error, stackTrace) {
          streamController.addError(error, stackTrace);
          sampler.markInferenceComplete();
        }
      });

      return CameraSession(
        controller: controller,
        sampledFrames: streamController.stream,
        sampler: sampler,
        sampleInterval: interval,
      );
    } catch (error) {
      throw classifyCameraFailure(error);
    }
  }

  Future<void> disposeSession(CameraSession? session) async {
    if (session == null) {
      return;
    }

    try {
      if (session.controller.value.isStreamingImages) {
        await session.controller.stopImageStream();
      }
    } catch (_) {
      // Best-effort shutdown if the controller is already stopping.
    }

    await session.controller.dispose();
    await _sampledFramesController?.close();
    _sampledFramesController = null;
  }

  Duration computeAdaptiveInterval({
    required Duration previous,
    required Duration inferenceDuration,
    Duration baseInterval = AppConstants.frameSampleInterval,
  }) {
    if (inferenceDuration <= AppConstants.slowInferenceThreshold) {
      return baseInterval;
    }

    final nextMs = math.max(
      baseInterval.inMilliseconds,
      (inferenceDuration.inMilliseconds * 1.25).round(),
    );
    return Duration(milliseconds: nextMs);
  }
}
