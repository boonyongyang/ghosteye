import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/teleprompter_settings.dart';

void main() {
  group('TeleprompterSettings', () {
    test('defaults preserve the original hardcoded teleprompter behaviour', () {
      const settings = TeleprompterSettings();

      expect(settings.textSize, TeleprompterTextSize.standard);
      expect(settings.density, TeleprompterDensity.cozy);
      expect(settings.pace, TeleprompterPace.natural);

      // Original constants: 1.0 scale, 10px line gap, 35ms char delay.
      expect(settings.textSize.scale, 1.0);
      expect(settings.density.lineGap, 10);
      expect(settings.pace.charDelay, const Duration(milliseconds: 35));
    });

    test('copyWith replaces only the provided fields', () {
      const settings = TeleprompterSettings();

      final resized = settings.copyWith(textSize: TeleprompterTextSize.large);
      expect(resized.textSize, TeleprompterTextSize.large);
      expect(resized.density, settings.density);
      expect(resized.pace, settings.pace);

      final repaced = resized.copyWith(pace: TeleprompterPace.brisk);
      expect(repaced.textSize, TeleprompterTextSize.large);
      expect(repaced.pace, TeleprompterPace.brisk);
    });

    test('equality and hashCode are value-based', () {
      const a = TeleprompterSettings(
        textSize: TeleprompterTextSize.compact,
        density: TeleprompterDensity.roomy,
        pace: TeleprompterPace.calm,
      );
      const b = TeleprompterSettings(
        textSize: TeleprompterTextSize.compact,
        density: TeleprompterDensity.roomy,
        pace: TeleprompterPace.calm,
      );
      const c = TeleprompterSettings(
        textSize: TeleprompterTextSize.large,
        density: TeleprompterDensity.roomy,
        pace: TeleprompterPace.calm,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('enum steps are ordered and distinct', () {
      expect(
        TeleprompterTextSize.compact.scale <
            TeleprompterTextSize.standard.scale,
        isTrue,
      );
      expect(
        TeleprompterTextSize.standard.scale < TeleprompterTextSize.large.scale,
        isTrue,
      );

      expect(
        TeleprompterDensity.tight.lineGap < TeleprompterDensity.cozy.lineGap,
        isTrue,
      );
      expect(
        TeleprompterDensity.cozy.lineGap < TeleprompterDensity.roomy.lineGap,
        isTrue,
      );

      // Brisker pace means a shorter delay between revealed characters.
      expect(
        TeleprompterPace.brisk.charDelay < TeleprompterPace.natural.charDelay,
        isTrue,
      );
      expect(
        TeleprompterPace.natural.charDelay < TeleprompterPace.calm.charDelay,
        isTrue,
      );
    });

    test('every value exposes a non-empty label', () {
      for (final value in TeleprompterTextSize.values) {
        expect(value.label, isNotEmpty);
      }
      for (final value in TeleprompterDensity.values) {
        expect(value.label, isNotEmpty);
      }
      for (final value in TeleprompterPace.values) {
        expect(value.label, isNotEmpty);
      }
    });
  });
}
