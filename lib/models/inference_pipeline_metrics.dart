import 'frame_preprocessor_settings.dart';

class DurationMetricSnapshot {
  const DurationMetricSnapshot({
    this.last,
    this.median,
    this.sampleCount = 0,
  });

  final Duration? last;
  final Duration? median;
  final int sampleCount;

  bool get hasSamples => sampleCount > 0;
}

class InferencePipelineMetrics {
  const InferencePipelineMetrics({
    required this.settings,
    this.frameCopy = const DurationMetricSnapshot(),
    this.preprocessing = const DurationMetricSnapshot(),
    this.modelInput = const DurationMetricSnapshot(),
    this.firstToken = const DurationMetricSnapshot(),
    this.fullResponse = const DurationMetricSnapshot(),
    this.completedResponses = 0,
    this.canceledResponses = 0,
    this.failedResponses = 0,
  });

  final FramePreprocessorSettings settings;
  final DurationMetricSnapshot frameCopy;
  final DurationMetricSnapshot preprocessing;
  final DurationMetricSnapshot modelInput;
  final DurationMetricSnapshot firstToken;
  final DurationMetricSnapshot fullResponse;
  final int completedResponses;
  final int canceledResponses;
  final int failedResponses;

  InferencePipelineMetrics copyWith({
    FramePreprocessorSettings? settings,
    DurationMetricSnapshot? frameCopy,
    DurationMetricSnapshot? preprocessing,
    DurationMetricSnapshot? modelInput,
    DurationMetricSnapshot? firstToken,
    DurationMetricSnapshot? fullResponse,
    int? completedResponses,
    int? canceledResponses,
    int? failedResponses,
  }) {
    return InferencePipelineMetrics(
      settings: settings ?? this.settings,
      frameCopy: frameCopy ?? this.frameCopy,
      preprocessing: preprocessing ?? this.preprocessing,
      modelInput: modelInput ?? this.modelInput,
      firstToken: firstToken ?? this.firstToken,
      fullResponse: fullResponse ?? this.fullResponse,
      completedResponses: completedResponses ?? this.completedResponses,
      canceledResponses: canceledResponses ?? this.canceledResponses,
      failedResponses: failedResponses ?? this.failedResponses,
    );
  }
}
