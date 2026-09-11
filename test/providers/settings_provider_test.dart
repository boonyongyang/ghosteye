import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/performance_preset.dart';
import 'package:ghosteye/models/teleprompter_settings.dart';
import 'package:ghosteye/providers/preferences_provider.dart';
import 'package:ghosteye/providers/session_controls_provider.dart';
import 'package:ghosteye/providers/teleprompter_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('settings providers load and persist known enum values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ghosteye.performance_preset': 'fast',
      'ghosteye.teleprompter_text_size': 'large',
      'ghosteye.teleprompter_density': 'roomy',
      'ghosteye.teleprompter_pace': 'brisk',
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(performancePresetProvider), PerformancePreset.fast);
    expect(
      container.read(teleprompterSettingsProvider),
      const TeleprompterSettings(
        textSize: TeleprompterTextSize.large,
        density: TeleprompterDensity.roomy,
        pace: TeleprompterPace.brisk,
      ),
    );

    container
        .read(performancePresetProvider.notifier)
        .setPreset(PerformancePreset.cinematic);
    container
        .read(teleprompterSettingsProvider.notifier)
        .setTextSize(TeleprompterTextSize.compact);

    expect(preferences.getString('ghosteye.performance_preset'), 'cinematic');
    expect(preferences.getString('ghosteye.teleprompter_text_size'), 'compact');
  });

  test('unknown persisted values fall back to safe defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ghosteye.performance_preset': 'removed',
      'ghosteye.teleprompter_pace': 'removed',
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(performancePresetProvider),
      PerformancePreset.balanced,
    );
    expect(
      container.read(teleprompterSettingsProvider).pace,
      TeleprompterPace.natural,
    );
  });
}
