import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/models/script_session.dart';

ScriptSession _makeSession({List<ScriptEntry> entries = const []}) {
  return ScriptSession(
    id: 'test-id',
    createdAt: DateTime.utc(2024, 1, 15, 10, 0),
    updatedAt: DateTime.utc(2024, 1, 15, 10, 5),
    entries: entries,
  );
}

void main() {
  group('ScriptSession', () {
    group('preview', () {
      test('returns "Empty take" when entries is empty', () {
        expect(_makeSession().preview, equals('Empty take'));
      });

      test('returns the text of the single entry for a one-entry session', () {
        final session = _makeSession(entries: [
          const ScriptEntry(type: ScriptEntryType.action, text: 'Rain falls.'),
        ]);
        expect(session.preview, equals('Rain falls.'));
      });

      test('joins first two entries with a space', () {
        final session = _makeSession(entries: [
          const ScriptEntry(type: ScriptEntryType.slugline, text: 'INT. ROOM'),
          const ScriptEntry(type: ScriptEntryType.action, text: 'Silence.'),
          const ScriptEntry(type: ScriptEntryType.character, text: 'MARA'),
        ]);
        expect(session.preview, equals('INT. ROOM Silence.'));
      });

      test('preview is trimmed', () {
        final session = _makeSession(entries: [
          const ScriptEntry(type: ScriptEntryType.slugline, text: 'INT. ROOM'),
          const ScriptEntry(type: ScriptEntryType.action, text: '  '),
        ]);
        expect(session.preview, equals('INT. ROOM'));
      });
    });

    test('lineCount equals entries length', () {
      final session = _makeSession(entries: [
        const ScriptEntry(type: ScriptEntryType.action, text: 'A'),
        const ScriptEntry(type: ScriptEntryType.dialogue, text: 'B'),
        const ScriptEntry(type: ScriptEntryType.character, text: 'C'),
      ]);
      expect(session.lineCount, equals(3));
    });

    test('lineCount is zero for an empty session', () {
      expect(_makeSession().lineCount, equals(0));
    });

    group('toJson / fromJson round-trip', () {
      test('round-trips a session with entries', () {
        final original = _makeSession(entries: [
          const ScriptEntry(
              type: ScriptEntryType.slugline, text: 'INT. ROOM - NIGHT'),
          const ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hello.'),
        ]);
        final restored = ScriptSession.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.createdAt, equals(original.createdAt));
        expect(restored.updatedAt, equals(original.updatedAt));
        expect(restored.entries, equals(original.entries));
        expect(restored, equals(original));
      });

      test('fromJson handles missing entries key', () {
        final json = <String, Object?>{
          'id': 'abc',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        };
        final session = ScriptSession.fromJson(json);
        expect(session.entries, isEmpty);
      });

      test('fromJson falls back to epoch for malformed date strings', () {
        final json = <String, Object?>{
          'id': 'abc',
          'createdAt': 'not-a-date',
          'updatedAt': 'not-a-date',
          'entries': <Object?>[],
        };
        final session = ScriptSession.fromJson(json);
        expect(
          session.createdAt,
          equals(DateTime.fromMillisecondsSinceEpoch(0)),
        );
        expect(
          session.updatedAt,
          equals(DateTime.fromMillisecondsSinceEpoch(0)),
        );
      });

      test('fromJson handles an empty map with safe defaults', () {
        final session = ScriptSession.fromJson(<String, Object?>{});
        expect(session.id, isEmpty);
        expect(session.entries, isEmpty);
      });
    });

    group('equality', () {
      test('two sessions with identical fields are equal', () {
        final a = _makeSession();
        final b = _makeSession();
        expect(a, equals(b));
      });

      test('sessions with different ids are not equal', () {
        final a = ScriptSession(
          id: 'a',
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          entries: [],
        );
        final b = ScriptSession(
          id: 'b',
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          entries: [],
        );
        expect(a, isNot(equals(b)));
      });

      test('sessions with different entries are not equal', () {
        final a = _makeSession(entries: [
          const ScriptEntry(type: ScriptEntryType.action, text: 'Hello'),
        ]);
        final b = _makeSession(entries: [
          const ScriptEntry(type: ScriptEntryType.action, text: 'World'),
        ]);
        expect(a, isNot(equals(b)));
      });

      test('sessions with different createdAt are not equal', () {
        final a = ScriptSession(
          id: 'x',
          createdAt: DateTime.utc(2024, 1),
          updatedAt: DateTime.utc(2024, 1),
          entries: [],
        );
        final b = ScriptSession(
          id: 'x',
          createdAt: DateTime.utc(2024, 2),
          updatedAt: DateTime.utc(2024, 1),
          entries: [],
        );
        expect(a, isNot(equals(b)));
      });
    });

    test('equal sessions have the same hashCode', () {
      final a = _makeSession();
      final b = _makeSession();
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
