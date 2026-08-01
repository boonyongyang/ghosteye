import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/performance_preset.dart';
import 'package:ghosteye/providers/preferences_provider.dart';
import 'package:ghosteye/providers/session_controls_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('captureEnabledProvider starts enabled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(captureEnabledProvider), isTrue);
  });

  test('captureEnabledProvider can be disabled (pause)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(captureEnabledProvider.notifier).state = false;

    expect(container.read(captureEnabledProvider), isFalse);
  });

  test('captureEnabledProvider can be re-enabled after pause (resume)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(captureEnabledProvider.notifier).state = false;
    container.read(captureEnabledProvider.notifier).state = true;

    expect(container.read(captureEnabledProvider), isTrue);
  });

  test('state changes are isolated between containers', () {
    final container1 = ProviderContainer();
    final container2 = ProviderContainer();
    addTearDown(container1.dispose);
    addTearDown(container2.dispose);

    container1.read(captureEnabledProvider.notifier).state = false;

    expect(container1.read(captureEnabledProvider), isFalse);
    expect(container2.read(captureEnabledProvider), isTrue);
  });

  test('toggling multiple times ends in the correct final state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // pause → resume → pause
    container.read(captureEnabledProvider.notifier).state = false;
    container.read(captureEnabledProvider.notifier).state = true;
    container.read(captureEnabledProvider.notifier).state = false;

    expect(container.read(captureEnabledProvider), isFalse);
  });

  group('performancePresetProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('defaults to balanced without a preferences instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(performancePresetProvider),
        PerformancePreset.balanced,
      );
    });

    test('hydrates a persisted preset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ghosteye.performance_preset': 'fast',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(performancePresetProvider),
        PerformancePreset.fast,
      );
    });

    test('setPreset persists and a fresh container rehydrates it', () async {
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer makeContainer() {
        final container = ProviderContainer(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      makeContainer()
          .read(performancePresetProvider.notifier)
          .setPreset(PerformancePreset.cinematic);

      expect(prefs.getString('ghosteye.performance_preset'), 'cinematic');
      expect(
        makeContainer().read(performancePresetProvider),
        PerformancePreset.cinematic,
      );
    });
  });
}
