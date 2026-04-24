import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/frame_preprocessor_settings.dart';
import 'package:ghosteye/providers/inference_pipeline_metrics_provider.dart';

const _testSettings = FramePreprocessorSettings(
  backend: FramePreprocessorBackend.dart,
  maxDimension: 512,
  jpegQuality: 80,
);

/// Returns a container whose metrics notifier uses [windowSize] instead of
/// the app constant, allowing the window-eviction tests to be fast and exact.
ProviderContainer _makeContainer({int windowSize = 10}) {
  return ProviderContainer(
    overrides: [
      inferencePipelineMetricsProvider.overrideWith(
        (_) => InferencePipelineMetricsNotifier(
          settings: _testSettings,
          windowSize: windowSize,
        ),
      ),
    ],
  );
}

void main() {
  group('InferencePipelineMetricsNotifier', () {
    test('initial state has zero counters and no samples', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final s = container.read(inferencePipelineMetricsProvider);
      expect(s.completedResponses, equals(0));
      expect(s.canceledResponses, equals(0));
      expect(s.failedResponses, equals(0));
      expect(s.frameCopy.hasSamples, isFalse);
      expect(s.preprocessing.hasSamples, isFalse);
      expect(s.modelInput.hasSamples, isFalse);
      expect(s.firstToken.hasSamples, isFalse);
      expect(s.fullResponse.hasSamples, isFalse);
    });

    group('recordFrameCopy', () {
      test('updates frameCopy with last value and sampleCount', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordFrameCopy(const Duration(milliseconds: 20));

        final snap = container.read(inferencePipelineMetricsProvider).frameCopy;
        expect(snap.last, equals(const Duration(milliseconds: 20)));
        expect(snap.sampleCount, equals(1));
        expect(snap.hasSamples, isTrue);
      });
    });

    group('recordPreprocessing', () {
      test('updates preprocessing snapshot', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordPreprocessing(const Duration(milliseconds: 50));

        final snap =
            container.read(inferencePipelineMetricsProvider).preprocessing;
        expect(snap.last, equals(const Duration(milliseconds: 50)));
        expect(snap.sampleCount, equals(1));
      });
    });

    group('recordModelInput', () {
      test('updates modelInput snapshot', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordModelInput(const Duration(milliseconds: 100));

        expect(
          container.read(inferencePipelineMetricsProvider).modelInput.last,
          equals(const Duration(milliseconds: 100)),
        );
      });
    });

    group('recordFirstToken', () {
      test('updates firstToken snapshot', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordFirstToken(const Duration(milliseconds: 300));

        expect(
          container.read(inferencePipelineMetricsProvider).firstToken.last,
          equals(const Duration(milliseconds: 300)),
        );
      });
    });

    group('recordFullResponse', () {
      test('increments completedResponses on each call', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        notifier.recordFullResponse(const Duration(milliseconds: 500));
        notifier.recordFullResponse(const Duration(milliseconds: 600));

        expect(
          container.read(inferencePipelineMetricsProvider).completedResponses,
          equals(2),
        );
      });

      test('updates fullResponse snapshot', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordFullResponse(const Duration(milliseconds: 500));

        expect(
          container.read(inferencePipelineMetricsProvider).fullResponse.last,
          equals(const Duration(milliseconds: 500)),
        );
      });
    });

    group('recordCanceledResponse', () {
      test('increments canceledResponses', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        notifier.recordCanceledResponse();
        notifier.recordCanceledResponse();
        notifier.recordCanceledResponse();

        expect(
          container.read(inferencePipelineMetricsProvider).canceledResponses,
          equals(3),
        );
      });
    });

    group('recordFailedResponse', () {
      test('increments failedResponses', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordFailedResponse();

        expect(
          container.read(inferencePipelineMetricsProvider).failedResponses,
          equals(1),
        );
      });
    });

    test('response counters are independent of each other', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(inferencePipelineMetricsProvider.notifier);
      notifier.recordFullResponse(const Duration(milliseconds: 100));
      notifier.recordCanceledResponse();
      notifier.recordFailedResponse();
      notifier.recordFailedResponse();

      final s = container.read(inferencePipelineMetricsProvider);
      expect(s.completedResponses, equals(1));
      expect(s.canceledResponses, equals(1));
      expect(s.failedResponses, equals(2));
    });

    group('median calculation', () {
      test('median of a single sample equals that sample', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container
            .read(inferencePipelineMetricsProvider.notifier)
            .recordFrameCopy(const Duration(milliseconds: 40));

        expect(
          container.read(inferencePipelineMetricsProvider).frameCopy.median,
          equals(const Duration(milliseconds: 40)),
        );
      });

      test('median of an odd number of samples is the middle value', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        // Added out-of-order to verify sorting: sorted = [10, 20, 30]
        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        notifier.recordFrameCopy(const Duration(milliseconds: 10));
        notifier.recordFrameCopy(const Duration(milliseconds: 30));
        notifier.recordFrameCopy(const Duration(milliseconds: 20));

        expect(
          container.read(inferencePipelineMetricsProvider).frameCopy.median,
          equals(const Duration(milliseconds: 20)),
        );
      });

      test(
          'median of an even count is the average of the two middle values',
          () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        // Sorted: [10, 20, 30, 40] → median = (20+30)/2 = 25 ms
        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        notifier.recordFrameCopy(const Duration(milliseconds: 10));
        notifier.recordFrameCopy(const Duration(milliseconds: 20));
        notifier.recordFrameCopy(const Duration(milliseconds: 30));
        notifier.recordFrameCopy(const Duration(milliseconds: 40));

        expect(
          container.read(inferencePipelineMetricsProvider).frameCopy.median,
          equals(const Duration(milliseconds: 25)),
        );
      });
    });

    group('window size enforcement', () {
      test('sampleCount never exceeds windowSize', () {
        final container = _makeContainer(windowSize: 3);
        addTearDown(container.dispose);

        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        for (var i = 0; i < 5; i++) {
          notifier.recordFrameCopy(Duration(milliseconds: i * 10));
        }

        expect(
          container.read(inferencePipelineMetricsProvider).frameCopy.sampleCount,
          equals(3),
        );
      });

      test('oldest sample is evicted when the window is full', () {
        final container = _makeContainer(windowSize: 3);
        addTearDown(container.dispose);

        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        // Fill window: [10, 20, 30]
        notifier.recordFrameCopy(const Duration(milliseconds: 10));
        notifier.recordFrameCopy(const Duration(milliseconds: 20));
        notifier.recordFrameCopy(const Duration(milliseconds: 30));
        // Evicts 10 → window becomes [20, 30, 400]
        notifier.recordFrameCopy(const Duration(milliseconds: 400));

        // Sorted: [20, 30, 400] → median = 30 ms
        final snap =
            container.read(inferencePipelineMetricsProvider).frameCopy;
        expect(snap.median, equals(const Duration(milliseconds: 30)));
        expect(snap.sampleCount, equals(3));
      });

      test('last value reflects the most recent sample after eviction', () {
        final container = _makeContainer(windowSize: 2);
        addTearDown(container.dispose);

        final notifier =
            container.read(inferencePipelineMetricsProvider.notifier);
        notifier.recordFrameCopy(const Duration(milliseconds: 10));
        notifier.recordFrameCopy(const Duration(milliseconds: 20));
        notifier.recordFrameCopy(const Duration(milliseconds: 99));

        expect(
          container.read(inferencePipelineMetricsProvider).frameCopy.last,
          equals(const Duration(milliseconds: 99)),
        );
      });
    });
  });
}
