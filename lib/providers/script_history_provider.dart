import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/script_entry.dart';
import '../models/script_session.dart';
import '../services/script_history_service.dart';

final scriptHistoryServiceProvider = Provider<ScriptHistoryService>((ref) {
  return ScriptHistoryService();
});

final scriptHistoryProvider =
    AsyncNotifierProvider<ScriptHistoryController, List<ScriptSession>>(
  ScriptHistoryController.new,
);

class ScriptHistoryController extends AsyncNotifier<List<ScriptSession>> {
  @override
  Future<List<ScriptSession>> build() async {
    return ref.read(scriptHistoryServiceProvider).loadSessions();
  }

  Future<void> syncSession({
    required String sessionId,
    required DateTime createdAt,
    required List<ScriptEntry> entries,
  }) async {
    if (entries.isEmpty) {
      return;
    }

    final session = ScriptSession(
      id: sessionId,
      createdAt: createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
      entries: List<ScriptEntry>.unmodifiable(entries),
    );

    final sessions = await ref.read(scriptHistoryServiceProvider).upsertSession(
          session,
        );
    state = AsyncData(sessions);
  }

  Future<void> deleteSession(String sessionId) async {
    final sessions =
        await ref.read(scriptHistoryServiceProvider).deleteSession(sessionId);
    state = AsyncData(sessions);
  }

  Future<void> clearAll() async {
    await ref.read(scriptHistoryServiceProvider).clearSessions();
    state = const AsyncData(<ScriptSession>[]);
  }
}
