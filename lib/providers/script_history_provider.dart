import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cinematic_mode.dart';
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
    CinematicMode? mode,
  }) async {
    if (entries.isEmpty) {
      return;
    }

    bool existingFavorite = false;
    for (final s in (state.valueOrNull ?? <ScriptSession>[])) {
      if (s.id == sessionId) {
        existingFavorite = s.isFavorite;
        break;
      }
    }

    final session = ScriptSession(
      id: sessionId,
      createdAt: createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
      entries: List<ScriptEntry>.unmodifiable(entries),
      mode: mode,
      isFavorite: existingFavorite,
    );

    final sessions = await ref.read(scriptHistoryServiceProvider).upsertSession(
          session,
        );
    state = AsyncData(sessions);
  }

  Future<void> toggleFavorite(String sessionId) async {
    final current = state.valueOrNull ?? <ScriptSession>[];
    ScriptSession? target;
    for (final s in current) {
      if (s.id == sessionId) {
        target = s;
        break;
      }
    }
    if (target == null) return;

    final updated = target.copyWith(isFavorite: !target.isFavorite);
    final sessions =
        await ref.read(scriptHistoryServiceProvider).upsertSession(updated);
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
