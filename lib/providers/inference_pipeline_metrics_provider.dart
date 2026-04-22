import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/frame_preprocessor_settings.dart';
import '../models/inference_pipeline_metrics.dart';
import '../services/frame_preprocessor.dart';

final framePreprocessorSettingsProvider = Provider<FramePreprocessorSettings>(
  (ref) {
    final requested = FramePreprocessorSettings.fromEnvironment();
    if (requested.backend == FramePreprocessorBackend.ffi &&
        !FramePreprocessor.supportsBackend(FramePreprocessorBackend.ffi)) {
      return requested.copyWith(backend: FramePreprocessorBackend.dart);
    }
    return requested;
  },
);

final inferencePipelineMetricsProvider = StateNotifierProvider<
    InferencePipelineMetricsNotifier, InferencePipelineMetrics>((ref) {
  return InferencePipelineMetricsNotifier(
    settings: ref.watch(framePreprocessorSettingsProvider),
  );
});

class InferencePipelineMetricsNotifier
    extends StateNotifier<InferencePipelineMetrics> {
  InferencePipelineMetricsNotifier({
    required FramePreprocessorSettings settings,
    int? windowSize,
  })  : windowSize = windowSize ?? AppConstants.metricsWindowSize,
        _frameCopySamples =
            ListQueue<int>(windowSize ?? AppConstants.metricsWindowSize),
        _preprocessingSamples =
            ListQueue<int>(windowSize ?? AppConstants.metricsWindowSize),
        _modelInputSamples =
            ListQueue<int>(windowSize ?? AppConstants.metricsWindowSize),
        _firstTokenSamples =
            ListQueue<int>(windowSize ?? AppConstants.metricsWindowSize),
        _fullResponseSamples =
            ListQueue<int>(windowSize ?? AppConstants.metricsWindowSize),
        super(InferencePipelineMetrics(settings: settings));

  final int windowSize;
  final ListQueue<int> _frameCopySamples;
  final ListQueue<int> _preprocessingSamples;
  final ListQueue<int> _modelInputSamples;
  final ListQueue<int> _firstTokenSamples;
  final ListQueue<int> _fullResponseSamples;

  void recordFrameCopy(Duration duration) {
    state = state.copyWith(
      frameCopy: _recordDuration(_frameCopySamples, duration),
    );
  }

  void recordPreprocessing(Duration duration) {
    state = state.copyWith(
      preprocessing: _recordDuration(_preprocessingSamples, duration),
    );
  }

  void recordModelInput(Duration duration) {
    state = state.copyWith(
      modelInput: _recordDuration(_modelInputSamples, duration),
    );
  }

  void recordFirstToken(Duration duration) {
    state = state.copyWith(
      firstToken: _recordDuration(_firstTokenSamples, duration),
    );
  }

  void recordFullResponse(Duration duration) {
    state = state.copyWith(
      fullResponse: _recordDuration(_fullResponseSamples, duration),
      completedResponses: state.completedResponses + 1,
    );
  }

  void recordCanceledResponse() {
    state = state.copyWith(canceledResponses: state.canceledResponses + 1);
  }

  void recordFailedResponse() {
    state = state.copyWith(failedResponses: state.failedResponses + 1);
  }

  DurationMetricSnapshot _recordDuration(
    ListQueue<int> samples,
    Duration duration,
  ) {
    if (samples.length == windowSize) {
      samples.removeFirst();
    }
    samples.addLast(duration.inMicroseconds);

    final ordered = samples.toList()..sort();
    final middleIndex = ordered.length ~/ 2;
    final medianMicros = ordered.length.isOdd
        ? ordered[middleIndex]
        : ((ordered[middleIndex - 1] + ordered[middleIndex]) / 2).round();

    return DurationMetricSnapshot(
      last: duration,
      median: Duration(microseconds: medianMicros),
      sampleCount: samples.length,
    );
  }
}
