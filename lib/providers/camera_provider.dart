import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../services/camera_service.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final cameraProvider =
    AsyncNotifierProvider<CameraControllerNotifier, CameraSession>(
        CameraControllerNotifier.new);

final cameraSessionViewProvider = Provider<AsyncValue<CameraSession>>((ref) {
  return ref.watch(cameraProvider);
});

class CameraControllerNotifier extends AsyncNotifier<CameraSession> {
  CameraSession? _session;

  @override
  Future<CameraSession> build() async {
    ref.onDispose(() async {
      await ref.read(cameraServiceProvider).disposeSession(_session);
    });

    final service = ref.read(cameraServiceProvider);
    _session =
        await service.initialize(interval: AppConstants.frameSampleInterval);
    return _session!;
  }

  void completeInference([Duration? inferenceDuration]) {
    final session = _session;
    if (session == null) {
      return;
    }

    session.sampler.markInferenceComplete();

    if (inferenceDuration == null) {
      return;
    }

    final service = ref.read(cameraServiceProvider);
    final nextInterval = service.computeAdaptiveInterval(
      previous: session.sampleInterval,
      inferenceDuration: inferenceDuration,
    );

    if (nextInterval == session.sampleInterval) {
      return;
    }

    session.sampler.updateInterval(nextInterval);
    _session = session.copyWith(sampleInterval: nextInterval);
    state = AsyncData(_session!);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await ref.read(cameraServiceProvider).disposeSession(_session);
    _session = await ref.read(cameraServiceProvider).initialize(
          interval: AppConstants.frameSampleInterval,
        );
    state = AsyncData(_session!);
  }
}
