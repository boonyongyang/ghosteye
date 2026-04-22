import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/frame_data.dart';
import '../services/gemma_service.dart';
import 'camera_provider.dart';
import 'cinematic_mode_provider.dart';
import 'frame_preprocessor_provider.dart';
import 'gemma_provider.dart';
import 'inference_pipeline_metrics_provider.dart';
import 'onboarding_provider.dart';
import 'session_controls_provider.dart';
import 'script_provider.dart';

enum InferenceActivity {
  idle,
  paused,
  processing,
  error,
}

class InferenceStatusState {
  const InferenceStatusState({
    this.activity = InferenceActivity.idle,
    this.lastInferenceDuration,
    this.errorMessage,
    this.errorKind,
    this.activeGenerationId,
  });

  final InferenceActivity activity;
  final Duration? lastInferenceDuration;
  final String? errorMessage;
  final InferenceFailureKind? errorKind;
  final int? activeGenerationId;

  InferenceStatusState copyWith({
    InferenceActivity? activity,
    Duration? lastInferenceDuration,
    String? errorMessage,
    InferenceFailureKind? errorKind,
    int? activeGenerationId,
  }) {
    return InferenceStatusState(
      activity: activity ?? this.activity,
      lastInferenceDuration:
          lastInferenceDuration ?? this.lastInferenceDuration,
      errorMessage: errorMessage,
      errorKind: errorKind,
      activeGenerationId: activeGenerationId,
    );
  }
}

class InferenceEvent {
  const InferenceEvent._({
    required this.activity,
    this.token,
    this.errorMessage,
    this.duration,
    this.generationId,
  });

  const InferenceEvent.processing(int generationId)
      : this._(
          activity: InferenceActivity.processing,
          generationId: generationId,
        );
  const InferenceEvent.token(String token, int generationId)
      : this._(
          activity: InferenceActivity.processing,
          token: token,
          generationId: generationId,
        );
  const InferenceEvent.completed(Duration duration, int generationId)
      : this._(
          activity: InferenceActivity.idle,
          duration: duration,
          generationId: generationId,
        );
  const InferenceEvent.error(String errorMessage, int generationId)
      : this._(
          activity: InferenceActivity.error,
          errorMessage: errorMessage,
          generationId: generationId,
        );

  final InferenceActivity activity;
  final String? token;
  final String? errorMessage;
  final Duration? duration;
  final int? generationId;
}

final inferenceStatusProvider = StateProvider<InferenceStatusState>((ref) {
  return const InferenceStatusState();
});

final inferenceGenerationCounterProvider = StateProvider<int>((ref) {
  return 0;
});

final inferenceProvider = StreamProvider.autoDispose<InferenceEvent>((ref) {
  final cameraSession = ref.watch(cameraProvider).valueOrNull;
  final gemmaState = ref.watch(gemmaProvider).valueOrNull;
  final onboardingState = ref.watch(onboardingProvider).valueOrNull;
  final mode = ref.watch(cinematicModeProvider);
  final shouldBlockForOnboarding = onboardingState?.directorTipsSeen != true;

  if (cameraSession == null || gemmaState == null || !gemmaState.isReady) {
    ref.read(inferenceStatusProvider.notifier).state =
        const InferenceStatusState();
    return const Stream.empty();
  }

  if (shouldBlockForOnboarding) {
    final previousStatus = ref.read(inferenceStatusProvider);
    ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
      activity: InferenceActivity.paused,
      lastInferenceDuration: previousStatus.lastInferenceDuration,
    );
    return const Stream.empty();
  }

  final controller = StreamController<InferenceEvent>();
  final scriptController = ref.read(scriptProvider.notifier);
  final metricsController = ref.read(inferencePipelineMetricsProvider.notifier);

  void recordMetrics(void Function() callback) {
    if (!AppConstants.enableFramePipelineMetrics) {
      return;
    }
    callback();
  }

  bool isGenerationStale(int generationId, Object modeAtStart) {
    return !ref.read(captureEnabledProvider) ||
        ref.read(scriptProvider).activeGenerationId != generationId ||
        ref.read(cinematicModeProvider) != modeAtStart;
  }

  void setCanceledStatus() {
    final activity = ref.read(captureEnabledProvider)
        ? InferenceActivity.idle
        : InferenceActivity.paused;
    ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
      activity: activity,
      activeGenerationId: null,
    );
  }

  Future<void> cancelCurrentGeneration(int generationId) async {
    await ref.read(gemmaProvider.notifier).cancelGeneration();
    scriptController.cancelActiveResponse();
    ref.read(cameraProvider.notifier).completeInference();
    recordMetrics(metricsController.recordCanceledResponse);
    setCanceledStatus();
  }

  Future<void> processFrame(FrameData frame) async {
    if (frame.copyDuration case final copyDuration?) {
      recordMetrics(() => metricsController.recordFrameCopy(copyDuration));
    }

    if (!ref.read(captureEnabledProvider)) {
      ref.read(inferenceStatusProvider.notifier).state =
          const InferenceStatusState(
        activity: InferenceActivity.paused,
      );
      ref.read(cameraProvider.notifier).completeInference();
      return;
    }

    final generationId =
        ref.read(inferenceGenerationCounterProvider.notifier).update(
              (state) => state + 1,
            );
    final stopwatch = Stopwatch()..start();

    ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
      activity: InferenceActivity.processing,
      activeGenerationId: generationId,
    );
    scriptController.startResponse(generationId);
    controller.add(InferenceEvent.processing(generationId));

    try {
      final preprocessingStopwatch = Stopwatch()..start();
      final preprocessedFrame =
          await ref.read(framePreprocessorProvider).preprocess(frame);
      preprocessingStopwatch.stop();
      recordMetrics(
        () => metricsController.recordPreprocessing(
          preprocessingStopwatch.elapsed,
        ),
      );

      if (isGenerationStale(generationId, mode)) {
        await cancelCurrentGeneration(generationId);
        return;
      }

      final sampledAt = frame.sampledAt;
      var firstTokenRecorded = false;
      final tokenStream = ref.read(gemmaServiceProvider).generateScriptTokens(
            imageBytes: preprocessedFrame.imageBytes,
            mode: mode,
            onInputReady: (duration) {
              recordMetrics(() => metricsController.recordModelInput(duration));
            },
          );

      await for (final token
          in tokenStream.timeout(AppConstants.fallbackInferenceTimeout)) {
        if (isGenerationStale(generationId, mode)) {
          await cancelCurrentGeneration(generationId);
          return;
        }

        if (!firstTokenRecorded && sampledAt != null) {
          firstTokenRecorded = true;
          recordMetrics(
            () => metricsController.recordFirstToken(
              DateTime.now().toUtc().difference(sampledAt),
            ),
          );
        }

        scriptController.appendToken(
          generationId: generationId,
          token: token,
        );
        controller.add(InferenceEvent.token(token, generationId));
      }

      if (isGenerationStale(generationId, mode)) {
        await cancelCurrentGeneration(generationId);
        return;
      }

      stopwatch.stop();
      scriptController.finishResponse(generationId);
      if (sampledAt != null) {
        recordMetrics(
          () => metricsController.recordFullResponse(
            DateTime.now().toUtc().difference(sampledAt),
          ),
        );
      }
      ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
        activity: InferenceActivity.idle,
        lastInferenceDuration: stopwatch.elapsed,
        activeGenerationId: null,
      );
      ref.read(cameraProvider.notifier).completeInference(stopwatch.elapsed);
      controller.add(InferenceEvent.completed(stopwatch.elapsed, generationId));
    } catch (error) {
      stopwatch.stop();
      final failure = classifyInferenceFailure(error);

      if (failure.kind == InferenceFailureKind.canceled ||
          isGenerationStale(generationId, mode)) {
        await cancelCurrentGeneration(generationId);
        return;
      }

      recordMetrics(metricsController.recordFailedResponse);
      scriptController.fail(
        generationId: generationId,
        message: failure.message,
      );
      ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
        activity: InferenceActivity.error,
        lastInferenceDuration: stopwatch.elapsed,
        errorMessage: failure.message,
        errorKind: failure.kind,
        activeGenerationId: null,
      );
      ref.read(cameraProvider.notifier).completeInference();
      controller.add(InferenceEvent.error(failure.message, generationId));
    }
  }

  final subscription = cameraSession.sampledFrames.listen(
    processFrame,
    onError: (Object error) {
      recordMetrics(metricsController.recordFailedResponse);
      final failure = classifyInferenceFailure(error);
      scriptController.cancelActiveResponse();
      ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
        activity: InferenceActivity.error,
        errorMessage: failure.message,
        errorKind: failure.kind,
        activeGenerationId: null,
      );
      controller.add(InferenceEvent.error(failure.message, -1));
    },
  );

  ref.onDispose(() async {
    await subscription.cancel();
    await controller.close();
  });

  return controller.stream;
});
