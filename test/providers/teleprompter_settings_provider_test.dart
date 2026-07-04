import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/teleprompter_settings.dart';
import 'package:ghosteye/providers/teleprompter_settings_provider.dart';

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
}
