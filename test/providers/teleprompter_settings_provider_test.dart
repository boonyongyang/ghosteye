import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/teleprompter_settings.dart';
import 'package:ghosteye/providers/preferences_provider.dart';
import 'package:ghosteye/providers/teleprompter_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('teleprompterSettingsProvider', () {
    test('starts at default settings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(teleprompterSettingsProvider),
        const TeleprompterSettings(),
      );
    });

    test('setTextSize updates only the text size', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(teleprompterSettingsProvider.notifier)
          .setTextSize(TeleprompterTextSize.large);

      final settings = container.read(teleprompterSettingsProvider);
      expect(settings.textSize, TeleprompterTextSize.large);
      expect(settings.density, TeleprompterDensity.cozy);
      expect(settings.pace, TeleprompterPace.natural);
    });

    test('setDensity updates only the density', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(teleprompterSettingsProvider.notifier)
          .setDensity(TeleprompterDensity.roomy);

      final settings = container.read(teleprompterSettingsProvider);
      expect(settings.density, TeleprompterDensity.roomy);
      expect(settings.textSize, TeleprompterTextSize.standard);
    });

    test('setPace updates only the pace', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(teleprompterSettingsProvider.notifier)
          .setPace(TeleprompterPace.brisk);

      final settings = container.read(teleprompterSettingsProvider);
      expect(settings.pace, TeleprompterPace.brisk);
      expect(settings.textSize, TeleprompterTextSize.standard);
      expect(settings.density, TeleprompterDensity.cozy);
    });

    test('successive setters accumulate independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(teleprompterSettingsProvider.notifier);
      notifier.setTextSize(TeleprompterTextSize.compact);
      notifier.setDensity(TeleprompterDensity.tight);
      notifier.setPace(TeleprompterPace.calm);

      expect(
        container.read(teleprompterSettingsProvider),
        const TeleprompterSettings(
          textSize: TeleprompterTextSize.compact,
          density: TeleprompterDensity.tight,
          pace: TeleprompterPace.calm,
        ),
      );
    });

    test('state changes are isolated between containers', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      container1
          .read(teleprompterSettingsProvider.notifier)
          .setTextSize(TeleprompterTextSize.large);

      expect(
        container1.read(teleprompterSettingsProvider).textSize,
        TeleprompterTextSize.large,
      );
      expect(
        container2.read(teleprompterSettingsProvider).textSize,
        TeleprompterTextSize.standard,
      );
    });
  });

  group('teleprompterSettingsProvider persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    ProviderContainer containerWith(SharedPreferences prefs) {
      final container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('hydrates persisted settings from shared preferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ghosteye.teleprompter_text_size': 'large',
        'ghosteye.teleprompter_density': 'roomy',
        'ghosteye.teleprompter_pace': 'brisk',
      });
      final prefs = await SharedPreferences.getInstance();

      final settings = containerWith(prefs).read(teleprompterSettingsProvider);
      expect(settings.textSize, TeleprompterTextSize.large);
      expect(settings.density, TeleprompterDensity.roomy);
      expect(settings.pace, TeleprompterPace.brisk);
    });

    test('falls back to defaults for unknown persisted values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ghosteye.teleprompter_text_size': 'gigantic',
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        containerWith(prefs).read(teleprompterSettingsProvider).textSize,
        TeleprompterTextSize.standard,
      );
    });

    test('setters persist and a fresh container rehydrates them', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = containerWith(prefs);

      container
          .read(teleprompterSettingsProvider.notifier)
          .setTextSize(TeleprompterTextSize.compact);
      container
          .read(teleprompterSettingsProvider.notifier)
          .setPace(TeleprompterPace.calm);

      expect(prefs.getString('ghosteye.teleprompter_text_size'), 'compact');
      expect(prefs.getString('ghosteye.teleprompter_pace'), 'calm');

      final rehydrated =
          containerWith(prefs).read(teleprompterSettingsProvider);
      expect(rehydrated.textSize, TeleprompterTextSize.compact);
      expect(rehydrated.pace, TeleprompterPace.calm);
    });

    test('no preferences instance keeps in-memory defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(teleprompterSettingsProvider),
        const TeleprompterSettings(),
      );
    });
  });
}
