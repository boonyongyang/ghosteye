import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/constants.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/models/script_session.dart';
import 'package:ghosteye/services/script_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ScriptHistoryService> _createService({
  required SharedPreferences preferences,
}) async {
  return ScriptHistoryService(
    loadPreferences: () async => preferences,
  );
}

ScriptSession _buildSession({
  required String id,
  required DateTime timestamp,
  String text = 'INT. APARTMENT - NIGHT',
}) {
  return ScriptSession(
    id: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    entries: <ScriptEntry>[
      ScriptEntry(
        type: ScriptEntryType.slugline,
        text: text,
      ),
    ],
  );
}

void main() {
  test('upsertSession persists, replaces, and keeps newest first', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    final first = _buildSession(
      id: 'first',
      timestamp: DateTime.utc(2026, 4, 21, 10),
    );
    final second = _buildSession(
      id: 'second',
      timestamp: DateTime.utc(2026, 4, 21, 11),
      text: 'EXT. ALLEY - DAWN',
    );

    await service.upsertSession(first);
    final sessions = await service.upsertSession(second);

    expect(sessions.map((session) => session.id), <String>['second', 'first']);

    final updatedFirst = _buildSession(
      id: 'first',
      timestamp: DateTime.utc(2026, 4, 21, 12),
      text: 'INT. CAB - NIGHT',
    );
    final replacedSessions = await service.upsertSession(updatedFirst);

    expect(
      replacedSessions.map((session) => session.id),
      <String>['first', 'second'],
    );
    expect(replacedSessions.first.entries.single.text, 'INT. CAB - NIGHT');
  });

  test('upsertSession respects the max saved session limit', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    for (var index = 0;
        index < AppConstants.maxSavedScriptSessions + 3;
        index++) {
      await service.upsertSession(
        _buildSession(
          id: 'session-$index',
          timestamp: DateTime.utc(2026, 4, 21, 12, index),
          text: 'Take $index',
        ),
      );
    }

    final sessions = await service.loadSessions();

    expect(sessions, hasLength(AppConstants.maxSavedScriptSessions));
    expect(sessions.first.id, 'session-14');
    expect(
      sessions.last.id,
      'session-3',
    );
  });

  test('deleteSession and clearSessions remove stored history', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    await service.upsertSession(
      _buildSession(
        id: 'keep',
        timestamp: DateTime.utc(2026, 4, 21, 10),
      ),
    );
    await service.upsertSession(
      _buildSession(
        id: 'delete',
        timestamp: DateTime.utc(2026, 4, 21, 11),
      ),
    );

    final remaining = await service.deleteSession('delete');
    expect(remaining.map((session) => session.id), <String>['keep']);

    await service.clearSessions();
    expect(await service.loadSessions(), isEmpty);
  });
}
