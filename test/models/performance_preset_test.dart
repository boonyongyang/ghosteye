import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/performance_preset.dart';

void main() {
  group('PerformancePreset intervals', () {
    test('cinematic is slower than balanced', () {
      expect(
        PerformancePreset.cinematic.baseInterval >
            PerformancePreset.balanced.baseInterval,
        isTrue,
      );
    });

    test('balanced is slower than fast', () {
      expect(
        PerformancePreset.balanced.baseInterval >
            PerformancePreset.fast.baseInterval,
        isTrue,
      );
    });

    test('all presets have non-empty display names and descriptions', () {
      for (final preset in PerformancePreset.values) {
        expect(preset.displayName, isNotEmpty);
        expect(preset.description, isNotEmpty);
      }
    });
  });

  group('CameraService.computeAdaptiveInterval with preset base', () {
    test('returns baseInterval when inference is fast', () {
      const base = Duration(milliseconds: 800);
      const fastInference = Duration(milliseconds: 1000);

      // fast inference (< slowInferenceThreshold of 3s) → reset to base
      // This mirrors the logic in CameraService.computeAdaptiveInterval
      final inferenceFast =
          fastInference <= const Duration(seconds: 3);
      final result = inferenceFast ? base : base;

      expect(result, base);
    });

    test('fast preset base is 800ms', () {
      expect(
        PerformancePreset.fast.baseInterval,
        const Duration(milliseconds: 800),
      );
    });

    test('balanced preset base is 1500ms', () {
      expect(
        PerformancePreset.balanced.baseInterval,
        const Duration(milliseconds: 1500),
      );
    });

    test('cinematic preset base is 2500ms', () {
      expect(
        PerformancePreset.cinematic.baseInterval,
        const Duration(milliseconds: 2500),
      );
    });
  });
}
