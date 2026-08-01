import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/frame_preprocessor_settings.dart';
import 'package:ghosteye/models/inference_pipeline_metrics.dart';

const _settings = FramePreprocessorSettings(
  backend: FramePreprocessorBackend.ffi,
  maxDimension: 768,
  jpegQuality: 88,
);

void main() {
  group('DurationMetricSnapshot', () {
    test('hasSamples is false when sampleCount is zero', () {
      const snapshot = DurationMetricSnapshot();
      expect(snapshot.hasSamples, isFalse);
      expect(snapshot.last, isNull);
      expect(snapshot.median, isNull);
    });

    test('hasSamples is true once samples are recorded', () {
      const snapshot = DurationMetricSnapshot(
        last: Duration(milliseconds: 12),
        median: Duration(milliseconds: 10),
        sampleCount: 3,
      );
      expect(snapshot.hasSamples, isTrue);
      expect(snapshot.last, const Duration(milliseconds: 12));
      expect(snapshot.median, const Duration(milliseconds: 10));
    });
  });

  group('InferencePipelineMetrics', () {
    test('defaults have empty snapshots and zero counters', () {
      const metrics = InferencePipelineMetrics(settings: _settings);

      expect(metrics.frameCopy.hasSamples, isFalse);
      expect(metrics.preprocessing.hasSamples, isFalse);
      expect(metrics.modelInput.hasSamples, isFalse);
      expect(metrics.firstToken.hasSamples, isFalse);
      expect(metrics.fullResponse.hasSamples, isFalse);
      expect(metrics.completedResponses, 0);
      expect(metrics.canceledResponses, 0);
      expect(metrics.failedResponses, 0);
    });

    test('copyWith replaces only the provided fields', () {
      const metrics = InferencePipelineMetrics(settings: _settings);

      final updated = metrics.copyWith(
        completedResponses: 4,
        preprocessing: const DurationMetricSnapshot(
          last: Duration(milliseconds: 50),
          median: Duration(milliseconds: 48),
          sampleCount: 2,
        ),
      );

      expect(updated.completedResponses, 4);
      expect(updated.preprocessing.sampleCount, 2);
      // Untouched fields are preserved.
      expect(updated.settings, same(metrics.settings));
      expect(updated.canceledResponses, metrics.canceledResponses);
      expect(updated.frameCopy.hasSamples, isFalse);
    });
  });
}
