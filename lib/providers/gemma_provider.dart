import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/model_source.dart';
import '../services/gemma_service.dart';

enum GemmaPhase {
  idle,
  checking,
  downloading,
  ready,
  error,
}

class GemmaState {
  const GemmaState({
    required this.phase,
    this.progress = 0,
    this.message,
    this.source,
    this.activeBackend,
    this.usedFallback = false,
    this.failureKind,
  });

  const GemmaState.idle() : this(phase: GemmaPhase.idle);

  final GemmaPhase phase;
  final int progress;
  final String? message;
  final ModelSourceConfig? source;
  final RuntimeBackend? activeBackend;
  final bool usedFallback;
  final GemmaStartupFailureKind? failureKind;

  bool get isReady => phase == GemmaPhase.ready;
  bool get hasError => phase == GemmaPhase.error;
  bool get usesImportedModel => source?.isImportedFile ?? false;

  GemmaState copyWith({
    GemmaPhase? phase,
    int? progress,
    String? message,
    ModelSourceConfig? source,
    RuntimeBackend? activeBackend,
    bool? usedFallback,
    GemmaStartupFailureKind? failureKind,
    bool clearMessage = false,
    bool clearSource = false,
    bool clearActiveBackend = false,
    bool clearFailureKind = false,
  }) {
    return GemmaState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      message: clearMessage ? null : message ?? this.message,
      source: clearSource ? null : source ?? this.source,
      activeBackend:
          clearActiveBackend ? null : activeBackend ?? this.activeBackend,
      usedFallback: usedFallback ?? this.usedFallback,
      failureKind: clearFailureKind ? null : failureKind ?? this.failureKind,
    );
  }
}

final gemmaServiceProvider = Provider<GemmaService>((ref) {
  final service = GemmaService();
  ref.onDispose(service.dispose);
  return service;
});

final gemmaProvider =
    AsyncNotifierProvider<GemmaNotifier, GemmaState>(GemmaNotifier.new);

final gemmaStateViewProvider = Provider<AsyncValue<GemmaState>>((ref) {
  return ref.watch(gemmaProvider);
});

class GemmaNotifier extends AsyncNotifier<GemmaState> {
  @override
  Future<GemmaState> build() async {
    return const GemmaState.idle();
  }

  Future<void> ensureReady() async {
    final service = ref.read(gemmaServiceProvider);
    ModelSourceConfig? source;

    try {
      source = await service.resolveModelSource();
      state = AsyncData(
        GemmaState(
          phase: GemmaPhase.checking,
          source: source,
        ),
      );

      final snapshot = await service.ensureReady(
        onProgress: (progress) {
          state = AsyncData(
            GemmaState(
              phase: GemmaPhase.downloading,
              progress: progress,
              message: 'Downloading ${AppConstants.modelDisplayName}',
              source: source,
              activeBackend: service.currentSnapshot?.backend,
            ),
          );
        },
      );

      state = AsyncData(
        GemmaState(
          phase: GemmaPhase.ready,
          progress: 100,
          message: snapshot.usedFallback
              ? '${AppConstants.modelDisplayName} ready on CPU fallback'
              : '${AppConstants.modelDisplayName} ready on ${snapshot.backend.name.toUpperCase()}',
          source: snapshot.source,
          activeBackend: snapshot.backend,
          usedFallback: snapshot.usedFallback,
        ),
      );
    } catch (error) {
      final failure = classifyGemmaStartupFailure(error, source: source);
      state = AsyncData(
        GemmaState(
          phase: GemmaPhase.error,
          message: failure.message,
          source: source ?? service.currentSource,
          failureKind: failure.kind,
          activeBackend: service.currentSnapshot?.backend,
          usedFallback: service.currentSnapshot?.usedFallback ?? false,
        ),
      );
    }
  }

  Future<void> importLocalModel() async {
    final previousState = state.valueOrNull ?? const GemmaState.idle();
    state = const AsyncLoading<GemmaState>().copyWithPrevious(state);

    try {
      final imported = await ref.read(gemmaServiceProvider).importLocalModel();
      if (!imported) {
        state = AsyncData(previousState);
        return;
      }
      await ensureReady();
    } catch (error) {
      final failure = classifyGemmaStartupFailure(
        error,
        source: const ModelSourceConfig(
          kind: ModelSourceKind.file,
          origin: ModelSourceOrigin.importedFile,
          location: '',
          label: 'Imported local model',
        ),
      );
      state = AsyncData(
        previousState.copyWith(
          phase: GemmaPhase.error,
          message: failure.message,
          failureKind: failure.kind,
          clearActiveBackend: true,
        ),
      );
    }
  }

  Future<void> useManagedDownload() async {
    state = const AsyncLoading<GemmaState>().copyWithPrevious(state);
    try {
      await ref.read(gemmaServiceProvider).useManagedDownload();
      await ensureReady();
    } catch (error) {
      final failure = classifyGemmaStartupFailure(error);
      state = AsyncData(
        GemmaState(
          phase: GemmaPhase.error,
          message: failure.message,
          failureKind: failure.kind,
          source: ref.read(gemmaServiceProvider).currentSource,
          activeBackend:
              ref.read(gemmaServiceProvider).currentSnapshot?.backend,
          usedFallback:
              ref.read(gemmaServiceProvider).currentSnapshot?.usedFallback ??
                  false,
        ),
      );
    }
  }

  Future<void> resetConversation() {
    return ref.read(gemmaServiceProvider).resetConversation();
  }

  Future<void> cancelGeneration() {
    return ref.read(gemmaServiceProvider).cancelGeneration();
  }
}
