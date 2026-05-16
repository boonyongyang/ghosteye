import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/script_entry.dart';
import '../models/script_session.dart';
import 'cinematic_mode_provider.dart';
import 'script_history_provider.dart';

const _noChange = Object();

class ScriptState {
  ScriptState({
    this.entries = const <ScriptEntry>[],
    this.liveResponse = '',
    this.isGenerating = false,
    this.errorMessage,
    this.scrollTick = 0,
    this.activeGenerationId,
    this.activeSessionId,
    this.activeSessionStartedAt,
  });

  final List<ScriptEntry> entries;
  final String liveResponse;
  final bool isGenerating;
  final String? errorMessage;
  final int scrollTick;
  final int? activeGenerationId;
  final String? activeSessionId;
  final DateTime? activeSessionStartedAt;

  ScriptState copyWith({
    List<ScriptEntry>? entries,
    String? liveResponse,
    bool? isGenerating,
    Object? errorMessage = _noChange,
    int? scrollTick,
    Object? activeGenerationId = _noChange,
    Object? activeSessionId = _noChange,
    Object? activeSessionStartedAt = _noChange,
  }) {
    return ScriptState(
      entries: entries ?? this.entries,
      liveResponse: liveResponse ?? this.liveResponse,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage == _noChange
          ? this.errorMessage
          : errorMessage as String?,
      scrollTick: scrollTick ?? this.scrollTick,
      activeGenerationId: activeGenerationId == _noChange
          ? this.activeGenerationId
          : activeGenerationId as int?,
      activeSessionId: activeSessionId == _noChange
          ? this.activeSessionId
          : activeSessionId as String?,
      activeSessionStartedAt: activeSessionStartedAt == _noChange
          ? this.activeSessionStartedAt
          : activeSessionStartedAt as DateTime?,
    );
  }
}

final scriptProvider =
    NotifierProvider<ScriptController, ScriptState>(ScriptController.new);

class ScriptController extends Notifier<ScriptState> {
  @override
  ScriptState build() => _createFreshState();

  void startResponse(int generationId) {
    state = state.copyWith(
      liveResponse: '',
      isGenerating: true,
      errorMessage: null,
      scrollTick: state.scrollTick + 1,
      activeGenerationId: generationId,
    );
  }

  void appendToken({
    required int generationId,
    required String token,
  }) {
    if (state.activeGenerationId != generationId) {
      return;
    }

    state = state.copyWith(
      liveResponse: '${state.liveResponse}$token',
      scrollTick: state.scrollTick + 1,
      activeGenerationId: generationId,
    );
  }

  void finishResponse(int generationId) {
    if (state.activeGenerationId != generationId) {
      return;
    }

    final liveResponse = state.liveResponse.trim();
    final parsed =
        liveResponse.isEmpty ? <ScriptEntry>[] : _parseEntries(liveResponse);
    final nextState = state.copyWith(
      entries: <ScriptEntry>[...state.entries, ...parsed],
      liveResponse: '',
      isGenerating: false,
      scrollTick: state.scrollTick + 1,
      activeGenerationId: null,
    );
    state = nextState;

    if (nextState.entries.isNotEmpty) {
      unawaited(_syncHistory(nextState));
    }
  }

  void fail({
    required int generationId,
    required String message,
  }) {
    if (state.activeGenerationId != generationId) {
      return;
    }

    state = state.copyWith(
      isGenerating: false,
      errorMessage: message,
      liveResponse: '',
      scrollTick: state.scrollTick + 1,
      activeGenerationId: null,
    );
  }

  void cancelActiveResponse() {
    if (state.activeGenerationId == null && state.liveResponse.isEmpty) {
      return;
    }

    state = state.copyWith(
      isGenerating: false,
      liveResponse: '',
      scrollTick: state.scrollTick + 1,
      activeGenerationId: null,
    );
  }

  void clear() {
    state = _createFreshState();
  }

  void loadSessionForReview(ScriptSession session) {
    state = _createFreshState().copyWith(
      entries: List<ScriptEntry>.unmodifiable(session.entries),
      scrollTick: state.scrollTick + 1,
    );
  }

  List<ScriptEntry> _parseEntries(String rawResponse) {
    final lines = rawResponse
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    var previousType = ScriptEntryType.action;
    return lines.map((line) {
      final type = _classifyLine(line, previousType);
      previousType = type;
      return ScriptEntry(type: type, text: line);
    }).toList(growable: false);
  }

  ScriptEntryType _classifyLine(String line, ScriptEntryType previousType) {
    final isUppercase = line == line.toUpperCase();
    final isSlugline =
        RegExp(r'^(INT|EXT|EST|INT\./EXT|I/E)[.\s-]').hasMatch(line);

    if (isSlugline) {
      return ScriptEntryType.slugline;
    }
    if (line.startsWith('(') && line.endsWith(')')) {
      return ScriptEntryType.parenthetical;
    }
    if (isUppercase && line.length <= 32 && !line.contains(':')) {
      return ScriptEntryType.character;
    }
    if (previousType == ScriptEntryType.character ||
        previousType == ScriptEntryType.parenthetical) {
      return ScriptEntryType.dialogue;
    }
    return ScriptEntryType.action;
  }

  ScriptState _createFreshState() {
    return ScriptState(
      activeSessionId: _createSessionId(),
      activeSessionStartedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _syncHistory(ScriptState snapshot) async {
    final sessionId = snapshot.activeSessionId ?? _createSessionId();
    final createdAt = snapshot.activeSessionStartedAt ?? DateTime.now().toUtc();
    final mode = ref.read(cinematicModeProvider);

    await ref.read(scriptHistoryProvider.notifier).syncSession(
          sessionId: sessionId,
          createdAt: createdAt,
          entries: snapshot.entries,
          mode: mode,
        );
  }

  String _createSessionId() {
    return DateTime.now().toUtc().microsecondsSinceEpoch.toString();
  }
}
