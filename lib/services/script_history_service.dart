import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/script_session.dart';

typedef LoadHistoryPreferencesFn = Future<SharedPreferences> Function();

class ScriptHistoryService {
  ScriptHistoryService({
    LoadHistoryPreferencesFn? loadPreferences,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const historyStorageKey = 'ghosteye.script_history';

  final LoadHistoryPreferencesFn _loadPreferences;

  Future<List<ScriptSession>> loadSessions() async {
    final preferences = await _loadPreferences();
    final storedSessions =
        preferences.getStringList(historyStorageKey) ?? <String>[];

    return storedSessions
        .map(_decodeSession)
        .whereType<ScriptSession>()
        .toList(growable: false);
  }

  Future<List<ScriptSession>> upsertSession(ScriptSession session) async {
    final sessions = await loadSessions();
    final updatedSessions = <ScriptSession>[
      session,
      ...sessions.where((savedSession) => savedSession.id != session.id),
    ];
    final limitedSessions = updatedSessions
        .take(AppConstants.maxSavedScriptSessions)
        .toList(growable: false);
    await _persistSessions(limitedSessions);
    return limitedSessions;
  }

  Future<List<ScriptSession>> deleteSession(String sessionId) async {
    final sessions = await loadSessions();
    final updatedSessions = sessions
        .where((session) => session.id != sessionId)
        .toList(growable: false);
    await _persistSessions(updatedSessions);
    return updatedSessions;
  }

  Future<void> clearSessions() async {
    final preferences = await _loadPreferences();
    await preferences.remove(historyStorageKey);
  }

  Future<void> _persistSessions(List<ScriptSession> sessions) async {
    final preferences = await _loadPreferences();
    final encodedSessions =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await preferences.setStringList(historyStorageKey, encodedSessions);
  }

  ScriptSession? _decodeSession(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return ScriptSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
