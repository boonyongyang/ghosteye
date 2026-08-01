import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/cinematic_mode.dart';

void main() {
  group('CinematicMode', () {
    test('exposes the expected display names', () {
      expect(CinematicMode.noir.displayName, 'NOIR');
      expect(CinematicMode.sciFi.displayName, 'SCI-FI');
      expect(CinematicMode.sitcom.displayName, 'SITCOM');
    });

    test('every mode has a distinct badge colour', () {
      final colors =
          CinematicMode.values.map((mode) => mode.badgeColor).toSet();
      expect(colors.length, equals(CinematicMode.values.length));
    });

    test('every mode has a non-empty short description', () {
      for (final mode in CinematicMode.values) {
        expect(mode.shortDescription, isNotEmpty);
      }
    });

    test('every mode has a distinct, Fountain-oriented system prompt', () {
      final prompts =
          CinematicMode.values.map((mode) => mode.systemPrompt).toList();

      expect(prompts.toSet().length, equals(prompts.length));
      for (final prompt in prompts) {
        expect(prompt, isNotEmpty);
        expect(prompt.toLowerCase(), contains('fountain'));
      }
    });
  });
}
