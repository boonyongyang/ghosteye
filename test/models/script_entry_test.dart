import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';

void main() {
  group('ScriptEntry', () {
    group('toJson / fromJson round-trip', () {
      test('round-trips all ScriptEntryType values', () {
        for (final type in ScriptEntryType.values) {
          final original = ScriptEntry(type: type, text: 'Sample text');
          final restored = ScriptEntry.fromJson(original.toJson());
          expect(restored, equals(original), reason: 'failed for type $type');
        }
      });

      test('toJson uses enum name for the type key', () {
        const entry = ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hi');
        final json = entry.toJson();
        expect(json['type'], equals('dialogue'));
        expect(json['text'], equals('Hi'));
      });

      test('fromJson falls back to action for an unknown type name', () {
        final entry = ScriptEntry.fromJson(<String, Object?>{
          'type': 'unknown_type',
          'text': 'Hello',
        });
        expect(entry.type, equals(ScriptEntryType.action));
        expect(entry.text, equals('Hello'));
      });

      test('fromJson uses action when type key is absent', () {
        final entry = ScriptEntry.fromJson(<String, Object?>{'text': 'Hello'});
        expect(entry.type, equals(ScriptEntryType.action));
      });

      test('fromJson returns empty text when text key is absent', () {
        final entry =
            ScriptEntry.fromJson(<String, Object?>{'type': 'slugline'});
        expect(entry.text, isEmpty);
      });

      test('fromJson handles an empty map', () {
        final entry = ScriptEntry.fromJson(<String, Object?>{});
        expect(entry.type, equals(ScriptEntryType.action));
        expect(entry.text, isEmpty);
      });
    });

    group('equality', () {
      test('two entries with the same type and text are equal', () {
        const a = ScriptEntry(type: ScriptEntryType.action, text: 'Rain.');
        const b = ScriptEntry(type: ScriptEntryType.action, text: 'Rain.');
        expect(a, equals(b));
      });

      test('entries with different types are not equal', () {
        const a = ScriptEntry(type: ScriptEntryType.action, text: 'Hello');
        const b = ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hello');
        expect(a, isNot(equals(b)));
      });

      test('entries with different text are not equal', () {
        const a = ScriptEntry(type: ScriptEntryType.action, text: 'Hello');
        const b = ScriptEntry(type: ScriptEntryType.action, text: 'World');
        expect(a, isNot(equals(b)));
      });

      test('an entry is equal to itself', () {
        const a = ScriptEntry(type: ScriptEntryType.character, text: 'MARA');
        // ignore: unrelated_type_equality_checks
        expect(a == a, isTrue);
      });

      test('an entry is not equal to a non-ScriptEntry object', () {
        const a = ScriptEntry(type: ScriptEntryType.action, text: 'Hello');
        // ignore: unrelated_type_equality_checks
        expect(a == 'Hello', isFalse);
      });
    });

    test('equal entries have the same hashCode', () {
      const a = ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hi');
      const b = ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hi');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different entries typically have different hashCodes', () {
      const a = ScriptEntry(type: ScriptEntryType.action, text: 'Rain.');
      const b = ScriptEntry(type: ScriptEntryType.dialogue, text: 'Rain.');
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
