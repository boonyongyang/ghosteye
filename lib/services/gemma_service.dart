import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_gemma/core/domain/download_error.dart';
import 'package:flutter_gemma/core/domain/download_exception.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../config/constants.dart';
import '../models/cinematic_mode.dart';
import '../models/model_source.dart';
import 'model_source_service.dart';

typedef GemmaProgressCallback = void Function(int progress);
typedef InferenceInputReadyCallback = void Function(Duration duration);
typedef IsModelInstalledFn = Future<bool> Function(String modelId);
typedef InstallModelFn = Future<void> Function({
  required ModelSourceConfig source,
  GemmaProgressCallback? onProgress,
});
typedef CreateModelFn = Future<InferenceModel> Function(
  PreferredBackend backend,
);

enum RuntimeBackend {
  gpu,
  cpu,
}

enum GemmaStartupFailureKind {
  missingToken,
  modelAccess,
  network,
  backendInitialization,
  modelLoad,
  localModel,
  unknown,
}

enum InferenceFailureKind {
  timeout,
  backendInitialization,
  modelAccess,
  network,
  unsupportedImageInput,
  canceled,
  modelSource,
  unknown,
}

class GemmaRuntimeSnapshot {
  const GemmaRuntimeSnapshot({
    required this.backend,
    required this.source,
    required this.usedFallback,
    required this.completedExchanges,
  });

  final RuntimeBackend backend;
  final ModelSourceConfig source;
  final bool usedFallback;
  final int completedExchanges;
}

class GemmaStartupFailure implements Exception {
  const GemmaStartupFailure({
    required this.kind,
    required this.message,
    this.originalError,
  });

  final GemmaStartupFailureKind kind;
  final String message;
  final Object? originalError;

  @override
  String toString() => message;
}

class InferenceFailure implements Exception {
  const InferenceFailure({
    required this.kind,
    required this.message,
    this.originalError,
  });

  final InferenceFailureKind kind;
  final String message;
  final Object? originalError;

  @override
  String toString() => message;
}

bool shouldRecycleConversation({
  required int completedExchanges,
  required int historyCharacters,
  int maxExchanges = AppConstants.maxChatExchanges,
  int maxHistoryCharacters = AppConstants.maxChatHistoryCharacters,
}) {
  return completedExchanges >= maxExchanges ||
      historyCharacters >= maxHistoryCharacters;
}

GemmaStartupFailure classifyGemmaStartupFailure(
  Object error, {
  ModelSourceConfig? source,
}) {
  if (error is GemmaStartupFailure) {
    return error;
  }

  if (source?.isFile ?? false) {
    final sourceMessage = error.toString().toLowerCase();
    if (sourceMessage.contains('unsupported model file type')) {
      return GemmaStartupFailure(
        kind: GemmaStartupFailureKind.localModel,
        message:
            'Ghosteye supports local model imports as .task, .litertlm, .bin, or .tflite files.',
        originalError: error,
      );
    }

    if (error is FileSystemException) {
      return GemmaStartupFailure(
        kind: GemmaStartupFailureKind.localModel,
        message: _localModelFailureMessage(source),
        originalError: error,
      );
    }

    if (sourceMessage.contains('model not found at path') ||
        sourceMessage.contains('no such file') ||
        sourceMessage.contains('does not exist') ||
        sourceMessage.contains('failed to open')) {
      return GemmaStartupFailure(
        kind: GemmaStartupFailureKind.localModel,
        message: _localModelFailureMessage(source),
        originalError: error,
      );
    }
  }

  if (error is DownloadException) {
    return switch (error.error) {
      UnauthorizedError() => GemmaStartupFailure(
          kind: GemmaStartupFailureKind.missingToken,
          message: _missingTokenMessage(source),
          originalError: error,
        ),
      ForbiddenError() || NotFoundError() => GemmaStartupFailure(
          kind: GemmaStartupFailureKind.modelAccess,
          message: _modelAccessMessage(source),
          originalError: error,
        ),
      NetworkError(:final message) => GemmaStartupFailure(
          kind: GemmaStartupFailureKind.network,
          message: _networkFailureMessage(source, message),
          originalError: error,
        ),
      RateLimitedError() ||
      ServerError() ||
      CanceledError() ||
      UnknownError() =>
        GemmaStartupFailure(
          kind: GemmaStartupFailureKind.network,
          message: _networkFailureMessage(source, error.toString()),
          originalError: error,
        ),
    };
  }

  final message = error.toString().toLowerCase();
  if (message.contains('huggingface') &&
      (message.contains('token') || message.contains('authentication'))) {
    return GemmaStartupFailure(
      kind: GemmaStartupFailureKind.missingToken,
      message: _missingTokenMessage(source),
      originalError: error,
    );
  }
  if (message.contains('401') ||
      message.contains('403') ||
      message.contains('forbidden')) {
    return GemmaStartupFailure(
      kind: GemmaStartupFailureKind.modelAccess,
      message: _modelAccessMessage(source),
      originalError: error,
    );
  }
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('timeout')) {
    return GemmaStartupFailure(
      kind: GemmaStartupFailureKind.network,
      message: _networkFailureMessage(source, null),
      originalError: error,
    );
  }
  if (message.contains('backend') ||
      message.contains('delegate') ||
      message.contains('gpu') ||
      message.contains('cpu')) {
    return GemmaStartupFailure(
      kind: GemmaStartupFailureKind.backendInitialization,
      message:
          'The on-device runtime could not initialize the model backend on this device.',
      originalError: error,
    );
  }
  if (message.contains('model') ||
      message.contains('active inference model') ||
      message.contains('session')) {
    return GemmaStartupFailure(
      kind: GemmaStartupFailureKind.modelLoad,
      message: source?.isFile ?? false
          ? _localModelFailureMessage(source)
          : 'The model download finished, but Ghosteye could not open it.',
      originalError: error,
    );
  }

  return GemmaStartupFailure(
    kind: GemmaStartupFailureKind.unknown,
    message: error.toString(),
    originalError: error,
  );
}

InferenceFailure classifyInferenceFailure(
  Object error, {
  ModelSourceConfig? source,
}) {
  if (error is InferenceFailure) {
    return error;
  }

  if (error is GemmaStartupFailure) {
    return switch (error.kind) {
      GemmaStartupFailureKind.missingToken ||
      GemmaStartupFailureKind.modelAccess =>
        InferenceFailure(
          kind: InferenceFailureKind.modelAccess,
          message: error.message,
          originalError: error,
        ),
      GemmaStartupFailureKind.network => InferenceFailure(
          kind: InferenceFailureKind.network,
          message: error.message,
          originalError: error,
        ),
      GemmaStartupFailureKind.localModel => InferenceFailure(
          kind: InferenceFailureKind.modelSource,
          message: error.message,
          originalError: error,
        ),
      GemmaStartupFailureKind.backendInitialization => InferenceFailure(
          kind: InferenceFailureKind.backendInitialization,
          message: error.message,
          originalError: error,
        ),
      GemmaStartupFailureKind.modelLoad ||
      GemmaStartupFailureKind.unknown =>
        InferenceFailure(
          kind: InferenceFailureKind.unknown,
          message: error.message,
          originalError: error,
        ),
    };
  }

  if (error is TimeoutException) {
    return InferenceFailure(
      kind: InferenceFailureKind.timeout,
      message:
          '${AppConstants.modelDisplayName} took too long to respond to this frame.',
      originalError: error,
    );
  }

  if (error is DownloadException) {
    return switch (error.error) {
      UnauthorizedError() ||
      ForbiddenError() ||
      NotFoundError() =>
        InferenceFailure(
          kind: InferenceFailureKind.modelAccess,
          message: _modelAccessMessage(source),
          originalError: error,
        ),
      NetworkError(:final message) => InferenceFailure(
          kind: InferenceFailureKind.network,
          message: _networkFailureMessage(source, message),
          originalError: error,
        ),
      CanceledError() => InferenceFailure(
          kind: InferenceFailureKind.canceled,
          message: 'Inference was canceled.',
          originalError: error,
        ),
      RateLimitedError() || ServerError() || UnknownError() => InferenceFailure(
          kind: InferenceFailureKind.network,
          message: _networkFailureMessage(source, error.toString()),
          originalError: error,
        ),
    };
  }

  if (error is ImageTokenizationException) {
    return InferenceFailure(
      kind: InferenceFailureKind.unsupportedImageInput,
      message:
          'The current frame could not be prepared for ${AppConstants.modelDisplayName}.',
      originalError: error,
    );
  }

  final message = error.toString().toLowerCase();
  if (message.contains('cancel')) {
    return InferenceFailure(
      kind: InferenceFailureKind.canceled,
      message: 'Inference was canceled.',
      originalError: error,
    );
  }
  if (message.contains('timeout')) {
    return InferenceFailure(
      kind: InferenceFailureKind.timeout,
      message:
          '${AppConstants.modelDisplayName} took too long to respond to this frame.',
      originalError: error,
    );
  }
  if (message.contains('token') && message.contains('image') ||
      message.contains('vision') ||
      message.contains('unsupported camera format')) {
    return InferenceFailure(
      kind: InferenceFailureKind.unsupportedImageInput,
      message:
          'Ghosteye could not prepare the current frame for multimodal inference.',
      originalError: error,
    );
  }
  if (message.contains('backend') ||
      message.contains('delegate') ||
      message.contains('gpu') ||
      message.contains('cpu')) {
    return InferenceFailure(
      kind: InferenceFailureKind.backendInitialization,
      message:
          'The on-device inference backend failed while processing a frame.',
      originalError: error,
    );
  }
  if (source?.isFile ?? false) {
    if (message.contains('model not found at path') ||
        message.contains('no such file') ||
        message.contains('failed to open')) {
      return InferenceFailure(
        kind: InferenceFailureKind.modelSource,
        message: _localModelFailureMessage(source),
        originalError: error,
      );
    }
  }
  if (message.contains('401') ||
      message.contains('403') ||
      message.contains('access') && message.contains('model')) {
    return InferenceFailure(
      kind: InferenceFailureKind.modelAccess,
      message: _modelAccessMessage(source),
      originalError: error,
    );
  }
  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection')) {
    return InferenceFailure(
      kind: InferenceFailureKind.network,
      message: _networkFailureMessage(source, null),
      originalError: error,
    );
  }

  return InferenceFailure(
    kind: InferenceFailureKind.unknown,
    message: error.toString(),
    originalError: error,
  );
}

class GemmaService {
  GemmaService({
    ModelSourceService? modelSourceService,
    IsModelInstalledFn? isModelInstalled,
    InstallModelFn? installModel,
    CreateModelFn? createModel,
  })  : _modelSourceService = modelSourceService ?? ModelSourceService(),
        _isModelInstalled = isModelInstalled ?? _defaultIsModelInstalled,
        _installModel = installModel ?? _defaultInstallModel,
        _createModel = createModel ?? _defaultCreateModel;

  final ModelSourceService _modelSourceService;
  final IsModelInstalledFn _isModelInstalled;
  final InstallModelFn _installModel;
  final CreateModelFn _createModel;

  InferenceModel? _model;
  InferenceChat? _chat;
  CinematicMode? _activeMode;
  RuntimeBackend? _activeBackend;
  ModelSourceConfig? _activeSource;
  var _usedFallback = false;
  var _completedExchanges = 0;

  ModelSourceConfig? get currentSource => _activeSource;

  GemmaRuntimeSnapshot? get currentSnapshot {
    final backend = _activeBackend;
    final source = _activeSource;
    if (backend == null || source == null) {
      return null;
    }
    return GemmaRuntimeSnapshot(
      backend: backend,
      source: source,
      usedFallback: _usedFallback,
      completedExchanges: _completedExchanges,
    );
  }

  Future<ModelSourceConfig> resolveModelSource({bool refresh = false}) async {
    return _modelSourceService.resolveSource();
  }

  Future<bool> isModelInstalled() async {
    final source = await resolveModelSource();
    return _isModelInstalled(source.modelId);
  }

  Future<GemmaRuntimeSnapshot> ensureReady({
    GemmaProgressCallback? onProgress,
  }) async {
    try {
      final previousSourceSignature = _activeSource?.signature;
      final source = await resolveModelSource();
      if (previousSourceSignature != source.signature) {
        await _resetRuntimeState(clearSource: false);
        _activeSource = source;
      }
      _activeSource ??= source;

      final installed = await _isModelInstalled(source.modelId);
      final installedSignature =
          await _modelSourceService.loadInstalledSourceSignature();
      final needsInstall = !installed || installedSignature != source.signature;

      if (needsInstall) {
        _assertDownloadAccess(source);
        await _installModel(source: source, onProgress: onProgress);
        await _modelSourceService.saveInstalledSourceSignature(source);
      }

      _model ??= await _createModelWithFallback();
      return currentSnapshot!;
    } catch (error) {
      throw classifyGemmaStartupFailure(
        error,
        source: _activeSource,
      );
    }
  }

  Future<bool> importLocalModel() async {
    try {
      final source = await _modelSourceService.importLocalModel();
      if (source == null) {
        return false;
      }

      await _resetRuntimeState(clearSource: true);
      _activeSource = source;
      return true;
    } catch (error) {
      throw classifyGemmaStartupFailure(
        error,
        source: const ModelSourceConfig(
          kind: ModelSourceKind.file,
          origin: ModelSourceOrigin.importedFile,
          location: '',
          label: 'Imported local model',
        ),
      );
    }
  }

  Future<void> useManagedDownload() async {
    await _modelSourceService.clearImportedModel();
    await _resetRuntimeState(clearSource: true);
  }

  Future<void> resetConversation() async {
    await _closeChat();
    _activeMode = null;
    _completedExchanges = 0;
  }

  Future<void> cancelGeneration() async {
    try {
      await _chat?.stopGeneration();
    } catch (_) {
      // Some platforms may not support cancellation reliably; ignore.
    }
  }

  Future<void> dispose() => _resetRuntimeState(clearSource: true);

  Stream<String> generateScriptTokens({
    required Uint8List imageBytes,
    required CinematicMode mode,
    InferenceInputReadyCallback? onInputReady,
  }) async* {
    try {
      await ensureReady();
      final chat = await _ensureChat(mode);

      final inputStopwatch = Stopwatch()..start();
      await chat.addQueryChunk(
        Message.withImage(
          text: AppConstants.directorPromptSuffix,
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
      inputStopwatch.stop();
      onInputReady?.call(inputStopwatch.elapsed);

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }

      _completedExchanges += 1;
    } catch (error) {
      throw classifyInferenceFailure(
        error,
        source: _activeSource,
      );
    }
  }

  Future<InferenceChat> _ensureChat(CinematicMode mode) async {
    if (_chat != null && _activeMode == mode) {
      if (_shouldRecycleChat(_chat!)) {
        await _chat!.clearHistory(
          replayHistory: <Message>[
            Message.systemInfo(text: mode.systemPrompt),
          ],
        );
        _completedExchanges = 0;
      }
      return _chat!;
    }

    await _closeChat();
    _activeMode = mode;
    final model = _model;
    if (model == null) {
      throw const GemmaStartupFailure(
        kind: GemmaStartupFailureKind.modelLoad,
        message: 'The model is not ready yet.',
      );
    }

    _chat = await model.createChat(
      modelType: ModelType.gemmaIt,
      supportImage: true,
      tokenBuffer: 256,
      temperature: 0.9,
      topK: 40,
    );
    await _chat!.addQueryChunk(
      Message.systemInfo(text: mode.systemPrompt),
    );
    return _chat!;
  }

  bool _shouldRecycleChat(InferenceChat chat) {
    final historyCharacters = chat.fullHistory.fold<int>(
      0,
      (total, message) => total + message.text.length,
    );
    return shouldRecycleConversation(
      completedExchanges: _completedExchanges,
      historyCharacters: historyCharacters,
    );
  }

  Future<InferenceModel> _createModelWithFallback() async {
    try {
      final model = await _createModel(PreferredBackend.gpu);
      _activeBackend = RuntimeBackend.gpu;
      _usedFallback = false;
      return model;
    } catch (_) {
      // Retry once on CPU if GPU delegate initialization fails.
    }

    try {
      final model = await _createModel(PreferredBackend.cpu);
      _activeBackend = RuntimeBackend.cpu;
      _usedFallback = true;
      return model;
    } catch (cpuError) {
      throw GemmaStartupFailure(
        kind: GemmaStartupFailureKind.backendInitialization,
        message:
            'Ghosteye could not initialize ${AppConstants.modelDisplayName} on GPU or CPU.',
        originalError: cpuError,
      );
    }
  }

  void _assertDownloadAccess(ModelSourceConfig source) {
    final isLegacyHuggingFaceFallback =
        source.origin == ModelSourceOrigin.legacyHuggingFace;
    if (!isLegacyHuggingFaceFallback || source.token != null) {
      return;
    }

    throw GemmaStartupFailure(
      kind: GemmaStartupFailureKind.missingToken,
      message: _missingTokenMessage(source),
    );
  }

  Future<void> _closeChat() async {
    if (_chat != null) {
      try {
        await _chat!.session.close();
      } finally {
        _chat = null;
      }
    }
  }

  Future<void> _resetRuntimeState({required bool clearSource}) async {
    await _closeChat();
    if (_model != null) {
      await _model!.close();
      _model = null;
    }
    _activeMode = null;
    _activeBackend = null;
    _usedFallback = false;
    _completedExchanges = 0;
    if (clearSource) {
      _activeSource = null;
    }
  }

  static Future<bool> _defaultIsModelInstalled(String modelId) {
    return FlutterGemma.isModelInstalled(modelId);
  }

  static Future<void> _defaultInstallModel({
    required ModelSourceConfig source,
    GemmaProgressCallback? onProgress,
  }) async {
    final installer = FlutterGemma.installModel(modelType: ModelType.gemmaIt);
    final configuredInstaller = switch (source.kind) {
      ModelSourceKind.network when source.token == null =>
        installer.fromNetwork(source.location),
      ModelSourceKind.network => installer.fromNetwork(
          source.location,
          token: source.token!,
        ),
      ModelSourceKind.file => installer.fromFile(source.location),
    };

    await configuredInstaller.withProgress((progress) {
      onProgress?.call(progress);
    }).install();
  }

  static Future<InferenceModel> _defaultCreateModel(
    PreferredBackend backend,
  ) {
    return FlutterGemma.getActiveModel(
      maxTokens: AppConstants.maxTokens,
      preferredBackend: backend,
    );
  }
}

String _missingTokenMessage(ModelSourceConfig? source) {
  if (source?.isLegacyHuggingFace ?? false) {
    return 'A Hugging Face token is required before Ghosteye can download ${AppConstants.modelDisplayName} from the legacy fallback source.';
  }

  if (source?.isHuggingFace ?? false) {
    return 'The active Hugging Face model source requires authentication before Ghosteye can continue.';
  }

  return 'The configured model download requires valid credentials before Ghosteye can continue.';
}

String _modelAccessMessage(ModelSourceConfig? source) {
  if (source?.isLegacyHuggingFace ?? false) {
    return 'The current Hugging Face token cannot access ${AppConstants.legacyModelRepository}.';
  }

  if (source?.isHuggingFace ?? false) {
    return 'Ghosteye could not access the active Hugging Face model source.';
  }

  if (source?.isFile ?? false) {
    return _localModelFailureMessage(source);
  }

  return 'Ghosteye could not access the configured managed model download.';
}

String _networkFailureMessage(ModelSourceConfig? source, String? details) {
  final baseMessage = switch (source?.kind) {
    ModelSourceKind.file => _localModelFailureMessage(source),
    ModelSourceKind.network when source?.isLegacyHuggingFace ?? false =>
      'Network access is required for the initial ${AppConstants.modelDisplayName} download from the legacy Hugging Face fallback.',
    ModelSourceKind.network =>
      'Network access is required while Ghosteye downloads ${AppConstants.modelDisplayName}.',
    null =>
      'Network access is required while Ghosteye prepares ${AppConstants.modelDisplayName}.',
  };

  if (details == null || details.isEmpty) {
    return baseMessage;
  }

  return '$baseMessage Details: $details';
}

String _localModelFailureMessage(ModelSourceConfig? source) {
  if (source?.isImportedFile ?? false) {
    return 'The imported model file is missing or unreadable. Import another supported model file or switch back to managed download.';
  }

  return 'The configured local model file is missing or unreadable. Check GHOSTEYE_GEMMA_MODEL_PATH or import another supported model file.';
}
