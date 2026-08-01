import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/cinematic_mode.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/models/script_session.dart';

ScriptSession _session({
  String id = 'test-id',
  DateTime? createdAt,
  DateTime? updatedAt,
  List<ScriptEntry> entries = const <ScriptEntry>[],
  CinematicMode? mode,
  bool isFavorite = false,
  String? thumbnail,
  String notes = '',
}) {
  final timestamp = DateTime.utc(2026, 5, 1);
  return ScriptSession(
    id: id,
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    entries: entries,
    mode: mode,
    isFavorite: isFavorite,
    thumbnail: thumbnail,
    notes: notes,
  );
}

void main() {
  group('ScriptSession preview', () {
    test('returns "Empty take" when entries is empty', () {
      expect(_session().preview, equals('Empty take'));
    });

    test('returns the text of the single entry for a one-entry session', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.action, text: 'Rain falls.'),
        ],
      );

      expect(session.preview, equals('Rain falls.'));
    });

    test('joins first two entries with a space', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.slugline, text: 'INT. ROOM'),
          const ScriptEntry(type: ScriptEntryType.action, text: 'Silence.'),
          const ScriptEntry(type: ScriptEntryType.character, text: 'MARA'),
        ],
      );

      expect(session.preview, equals('INT. ROOM Silence.'));
    });

    test('preview is trimmed', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.slugline, text: 'INT. ROOM'),
          const ScriptEntry(type: ScriptEntryType.action, text: '  '),
        ],
      );

      expect(session.preview, equals('INT. ROOM'));
    });
  });

  group('ScriptSession title', () {
    test('returns first slugline when present', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(
              type: ScriptEntryType.action, text: 'Rain hits the window.'),
          const ScriptEntry(
              type: ScriptEntryType.slugline, text: 'INT. OFFICE - NIGHT'),
          const ScriptEntry(type: ScriptEntryType.character, text: 'DETECTIVE'),
        ],
      );

      expect(session.title, 'INT. OFFICE - NIGHT');
    });

    test('falls back to first character name when no slugline', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(
              type: ScriptEntryType.action, text: 'A figure emerges.'),
          const ScriptEntry(type: ScriptEntryType.character, text: 'MARCO'),
        ],
      );

      expect(session.title, 'MARCO');
    });

    test('falls back to first action line when no slugline or character', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(
              type: ScriptEntryType.action, text: 'Darkness. A hum.'),
        ],
      );

      expect(session.title, 'Darkness. A hum.');
    });

    test('truncates long action lines at 50 chars with ellipsis', () {
      final longText = 'A' * 60;
      final session = _session(
        entries: <ScriptEntry>[
          ScriptEntry(type: ScriptEntryType.action, text: longText),
        ],
      );

      expect(session.title, '${'A' * 50}…');
    });

    test('skips short action lines (<=4 chars) when looking for title', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.action, text: 'Hi.'),
          const ScriptEntry(
              type: ScriptEntryType.action, text: 'Longer action here.'),
        ],
      );

      expect(session.title, 'Longer action here.');
    });

    test('returns Untitled take for empty entries', () {
      expect(_session().title, 'Untitled take');
    });
  });

  group('ScriptSession counters', () {
    test('lineCount equals entries length', () {
      final session = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.action, text: 'A'),
          const ScriptEntry(type: ScriptEntryType.dialogue, text: 'B'),
          const ScriptEntry(type: ScriptEntryType.character, text: 'C'),
        ],
      );

      expect(session.lineCount, equals(3));
    });

    test('lineCount is zero for an empty session', () {
      expect(_session().lineCount, equals(0));
    });
  });

  group('ScriptSession JSON round-trip', () {
    test('round-trips a session with entries', () {
      final original = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(
              type: ScriptEntryType.slugline, text: 'INT. ROOM - NIGHT'),
          const ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hello.'),
        ],
      );

      final restored = ScriptSession.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.updatedAt, equals(original.updatedAt));
      expect(restored.entries, equals(original.entries));
      expect(restored, equals(original));
    });

    test('serialises and deserialises mode and isFavorite', () {
      final original = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(
              type: ScriptEntryType.slugline, text: 'EXT. ROOFTOP - DUSK'),
        ],
        mode: CinematicMode.sciFi,
        isFavorite: true,
      );

      final decoded = ScriptSession.fromJson(original.toJson());

      expect(decoded.mode, CinematicMode.sciFi);
      expect(decoded.isFavorite, isTrue);
      expect(decoded.title, 'EXT. ROOFTOP - DUSK');
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

    test('handles legacy JSON missing mode and isFavorite', () {
      final json = <String, Object?>{
        'id': 'legacy',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entries': <Object?>[],
      };

      final session = ScriptSession.fromJson(json);

      expect(session.mode, isNull);
      expect(session.isFavorite, isFalse);
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

  group('ScriptSession.copyWith', () {
    test('toggles isFavorite while preserving all other fields', () {
      final original = _session(
        mode: CinematicMode.noir,
        isFavorite: false,
        entries: <ScriptEntry>[
          const ScriptEntry(
              type: ScriptEntryType.slugline, text: 'INT. CAFE - DAY'),
        ],
      );

      final pinned = original.copyWith(isFavorite: true);

      expect(pinned.isFavorite, isTrue);
      expect(pinned.id, original.id);
      expect(pinned.mode, original.mode);
      expect(pinned.entries, original.entries);
    });
  });

  group('ScriptSession thumbnail', () {
    test('hasThumbnail reflects presence of a non-empty value', () {
      expect(_session().hasThumbnail, isFalse);
      expect(_session(thumbnail: '').hasThumbnail, isFalse);
      expect(_session(thumbnail: 'abc123').hasThumbnail, isTrue);
    });

    test('round-trips the thumbnail through JSON', () {
      final original = _session(
        thumbnail: 'QUJD',
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.action, text: 'A shot.'),
        ],
      );

      final restored = ScriptSession.fromJson(original.toJson());

      expect(restored.thumbnail, equals('QUJD'));
      expect(restored, equals(original));
    });

    test('omits the thumbnail key when there is no thumbnail', () {
      expect(_session().toJson().containsKey('thumbnail'), isFalse);
    });

    test('legacy JSON without a thumbnail decodes to null', () {
      final json = <String, Object?>{
        'id': 'legacy',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entries': <Object?>[],
      };

      expect(ScriptSession.fromJson(json).thumbnail, isNull);
    });

    test('copyWith preserves the thumbnail across a favorite toggle', () {
      final original = _session(thumbnail: 'QUJD');

      final pinned = original.copyWith(isFavorite: true);

      expect(pinned.isFavorite, isTrue);
      expect(pinned.thumbnail, equals('QUJD'));
    });

    test('sessions differing only by thumbnail are not equal', () {
      expect(
        _session(thumbnail: 'AAAA'),
        isNot(equals(_session(thumbnail: 'BBBB'))),
      );
    });
  });

  group('ScriptSession notes', () {
    test('defaults to empty and hasNotes reflects trimmed content', () {
      expect(_session().notes, isEmpty);
      expect(_session().hasNotes, isFalse);
      expect(_session(notes: '   ').hasNotes, isFalse);
      expect(_session(notes: 'Push in on the door').hasNotes, isTrue);
    });

    test('round-trips notes through JSON', () {
      final original = _session(notes: 'Reshoot wider next take');
      final restored = ScriptSession.fromJson(original.toJson());

      expect(restored.notes, equals('Reshoot wider next take'));
      expect(restored, equals(original));
    });

    test('omits the notes key when empty', () {
      expect(_session().toJson().containsKey('notes'), isFalse);
      expect(_session(notes: 'x').toJson()['notes'], equals('x'));
    });

    test('legacy JSON without notes decodes to empty string', () {
      final json = <String, Object?>{
        'id': 'legacy',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entries': <Object?>[],
      };

      expect(ScriptSession.fromJson(json).notes, isEmpty);
    });

    test('copyWith updates notes while preserving other fields', () {
      final original = _session(thumbnail: 'QUJD', isFavorite: true);
      final annotated = original.copyWith(notes: 'Cutaway to clock');

      expect(annotated.notes, equals('Cutaway to clock'));
      expect(annotated.thumbnail, equals('QUJD'));
      expect(annotated.isFavorite, isTrue);
    });

    test('sessions differing only by notes are not equal', () {
      expect(
        _session(notes: 'take 1'),
        isNot(equals(_session(notes: 'take 2'))),
      );
    });
  });

  group('ScriptSession equality', () {
    test('two sessions with identical fields are equal', () {
      final a = _session();
      final b = _session();

      expect(a, equals(b));
    });

    test('sessions with different ids are not equal', () {
      final a = _session(id: 'a');
      final b = _session(id: 'b');

      expect(a, isNot(equals(b)));
    });

    test('sessions with different entries are not equal', () {
      final a = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.action, text: 'Hello'),
        ],
      );
      final b = _session(
        entries: <ScriptEntry>[
          const ScriptEntry(type: ScriptEntryType.action, text: 'World'),
        ],
      );

      expect(a, isNot(equals(b)));
    });

    test('sessions with different createdAt are not equal', () {
      final a = _session(createdAt: DateTime.utc(2024, 1));
      final b = _session(createdAt: DateTime.utc(2024, 2));

      expect(a, isNot(equals(b)));
    });

    test('equal sessions have the same hashCode', () {
      final a = _session();
      final b = _session();

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
