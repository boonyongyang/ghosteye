import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/cinematic_mode.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/models/script_session.dart';
import 'package:ghosteye/providers/script_history_provider.dart';
import 'package:ghosteye/services/script_history_service.dart';
import 'package:ghosteye/widgets/script_history_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScriptSession _makeSession({
  required String id,
  required String slugline,
  CinematicMode? mode,
  bool isFavorite = false,
}) {
  return ScriptSession(
    id: id,
    createdAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 1),
    entries: <ScriptEntry>[
      ScriptEntry(type: ScriptEntryType.slugline, text: slugline),
    ],
    mode: mode,
    isFavorite: isFavorite,
  );
}

Widget _buildSheet({
  List<ScriptSession> sessions = const <ScriptSession>[],
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      scriptHistoryServiceProvider.overrideWithValue(
        ScriptHistoryService(
          loadPreferences: () async {
            SharedPreferences.setMockInitialValues(<String, Object>{});
            return SharedPreferences.getInstance();
          },
        ),
      ),
      scriptHistoryProvider.overrideWith(() {
        return _FixedHistoryController(sessions);
      }),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: ScriptHistorySheet(
          onSelectSession: (_) async {},
          onExportSession: (_) async {},
        ),
      ),
    ),
  );
}

class _FixedHistoryController
    extends AsyncNotifier<List<ScriptSession>>
    implements ScriptHistoryController {
  _FixedHistoryController(this._sessions);

  final List<ScriptSession> _sessions;

  @override
  Future<List<ScriptSession>> build() async => _sessions;

  @override
  Future<void> toggleFavorite(String sessionId) async {
    final updated = state.value!.map((s) {
      return s.id == sessionId ? s.copyWith(isFavorite: !s.isFavorite) : s;
    }).toList();
    state = AsyncData(updated);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    state = AsyncData(
      state.value!.where((s) => s.id != sessionId).toList(),
    );
  }

  @override
  Future<void> clearAll() async => state = const AsyncData(<ScriptSession>[]);

  @override
  Future<void> syncSession({
    required String sessionId,
    required DateTime createdAt,
    required List<ScriptEntry> entries,
    CinematicMode? mode,
    Uint8List? thumbnailSource,
  }) async {}
}

void main() {
  testWidgets('shows Take Library title and auto-generated title on card',
      (tester) async {
    final sessions = <ScriptSession>[
      _makeSession(
        id: 'a',
        slugline: 'INT. ROOFTOP - NIGHT',
        mode: CinematicMode.noir,
      ),
    ];

    await tester.pumpWidget(_buildSheet(sessions: sessions));
    await tester.pump();

    expect(find.text('Take Library'), findsOneWidget);
    expect(find.text('INT. ROOFTOP - NIGHT'), findsOneWidget);
  });

  testWidgets('shows mode badge for sessions with a recorded mode',
      (tester) async {
    final sessions = <ScriptSession>[
      _makeSession(id: 'a', slugline: 'EXT. ALLEY - DAWN', mode: CinematicMode.sciFi),
    ];

    await tester.pumpWidget(_buildSheet(sessions: sessions));
    await tester.pump();

    // filter bar always shows all mode tabs + card has its own badge → ≥2
    expect(find.text('SCI-FI'), findsAtLeastNWidgets(2));
  });

  testWidgets('filter tab FAVORITES shows only favorited takes', (tester) async {
    final sessions = <ScriptSession>[
      _makeSession(id: 'fav', slugline: 'INT. LAB - DAY', mode: CinematicMode.sciFi, isFavorite: true),
      _makeSession(id: 'unfav', slugline: 'EXT. PARK - NOON', mode: CinematicMode.noir),
    ];

    await tester.pumpWidget(_buildSheet(sessions: sessions));
    await tester.pump();

    await tester.tap(find.text('★').first);
    await tester.pump();

    expect(find.text('INT. LAB - DAY'), findsOneWidget);
    expect(find.text('EXT. PARK - NOON'), findsNothing);
  });

  testWidgets('mode filter tab shows only matching takes', (tester) async {
    final sessions = <ScriptSession>[
      _makeSession(id: 'n', slugline: 'INT. OFFICE - NIGHT', mode: CinematicMode.noir),
      _makeSession(id: 's', slugline: 'EXT. SPACE - ALWAYS', mode: CinematicMode.sciFi),
    ];

    await tester.pumpWidget(_buildSheet(sessions: sessions));
    await tester.pump();

    // filter bar appears before card badges in the tree — tap the first NOIR
    await tester.tap(find.text('NOIR').first);
    await tester.pump();

    expect(find.text('INT. OFFICE - NIGHT'), findsOneWidget);
    expect(find.text('EXT. SPACE - ALWAYS'), findsNothing);
  });

  testWidgets('tapping star toggles isFavorite on the card', (tester) async {
    final sessions = <ScriptSession>[
      _makeSession(id: 'a', slugline: 'INT. CAFE - DAY', mode: CinematicMode.sitcom),
    ];

    await tester.pumpWidget(_buildSheet(sessions: sessions));
    await tester.pump();

    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('favorites are sorted to the top of the list', (tester) async {
    final sessions = <ScriptSession>[
      _makeSession(id: 'first', slugline: 'INT. ALLEY - NIGHT', mode: CinematicMode.noir),
      _makeSession(id: 'fav', slugline: 'EXT. ROOFTOP - DUSK', mode: CinematicMode.sciFi, isFavorite: true),
    ];

    await tester.pumpWidget(_buildSheet(sessions: sessions));
    await tester.pump();

    final titles = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data ?? '')
        .where((t) => t.startsWith('INT.') || t.startsWith('EXT.'))
        .toList();

    expect(titles.first, 'EXT. ROOFTOP - DUSK');
  });

  testWidgets('shows empty state for empty session list', (tester) async {
    await tester.pumpWidget(_buildSheet());
    await tester.pump();

    expect(find.textContaining('Ghosteye will save'), findsOneWidget);
  });
}
