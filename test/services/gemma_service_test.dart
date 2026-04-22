import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/model_source.dart';
import 'package:ghosteye/services/gemma_service.dart';
import 'package:ghosteye/services/model_source_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInferenceModel extends InferenceModel {
  InferenceChat? _chat;

  @override
  InferenceChat? get chat => _chat;

  @override
  set chat(InferenceChat? value) => _chat = value;

  bool isClosed = false;

  @override
  ModelFileType get fileType => ModelFileType.task;

  @override
  int get maxTokens => 512;

  @override
  InferenceModelSession? get session => null;

  @override
  Future<InferenceModelSession> createSession({
    double temperature = .8,
    int randomSeed = 1,
    int topK = 1,
    double? topP,
    String? loraPath,
    bool? enableVisionModality,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

Future<ModelSourceService> _createSourceService({
  String? importedPath,
  String? installedSourceSignature,
  String? configuredModelPath,
  String? configuredModelUrl,
  String? configuredToken,
}) async {
  SharedPreferences.setMockInitialValues(
    <String, Object>{
      if (importedPath != null)
        ModelSourceService.importedModelPathKey: importedPath,
      if (installedSourceSignature != null)
        ModelSourceService.installedSourceSignatureKey:
            installedSourceSignature,
    },
  );
  final preferences = await SharedPreferences.getInstance();

  return ModelSourceService(
    loadPreferences: () async => preferences,
    loadDocumentsDirectory: () async => Directory.systemTemp,
    pickModelFile: () async => null,
    configuredModelPath: configuredModelPath,
    configuredModelUrl: configuredModelUrl,
    configuredToken: configuredToken,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() {
    messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
      return Directory.systemTemp.path;
    });
  });

  tearDownAll(() {
    messenger.setMockMethodCallHandler(pathProviderChannel, null);
  });

  test('GemmaService falls back to CPU after GPU initialization failure',
      () async {
    final requestedBackends = <PreferredBackend>[];
    final cpuModel = _FakeInferenceModel();
    const source = ModelSourceConfig(
      kind: ModelSourceKind.network,
      origin: ModelSourceOrigin.envUrl,
      location: 'https://cdn.example.com/gemma.task',
      label: 'Managed download',
    );
    final sourceService = await _createSourceService(
      configuredModelUrl: source.location,
      installedSourceSignature: source.signature,
    );
    final service = GemmaService(
      modelSourceService: sourceService,
      isModelInstalled: (_) async => true,
      createModel: (backend) async {
        requestedBackends.add(backend);
        if (backend == PreferredBackend.gpu) {
          throw Exception('GPU delegate failed');
        }
        return cpuModel;
      },
    );
    addTearDown(service.dispose);

    final snapshot = await service.ensureReady();

    expect(
      requestedBackends,
      <PreferredBackend>[PreferredBackend.gpu, PreferredBackend.cpu],
    );
    expect(snapshot.backend, RuntimeBackend.cpu);
    expect(snapshot.usedFallback, isTrue);
    expect(snapshot.source.origin, ModelSourceOrigin.envUrl);
  });

  test('shouldRecycleConversation enforces exchange and history limits', () {
    expect(
      shouldRecycleConversation(
        completedExchanges: 8,
        historyCharacters: 10,
      ),
      isTrue,
    );
    expect(
      shouldRecycleConversation(
        completedExchanges: 1,
        historyCharacters: 6000,
      ),
      isTrue,
    );
    expect(
      shouldRecycleConversation(
        completedExchanges: 1,
        historyCharacters: 100,
      ),
      isFalse,
    );
  });

  test('Gemma startup failures classify managed and local source issues', () {
    const managedSource = ModelSourceConfig(
      kind: ModelSourceKind.network,
      origin: ModelSourceOrigin.envUrl,
      location: 'https://cdn.example.com/gemma.task',
      label: 'Managed download',
    );
    const localSource = ModelSourceConfig(
      kind: ModelSourceKind.file,
      origin: ModelSourceOrigin.importedFile,
      location: '/tmp/gemma.task',
      label: 'Imported local model',
    );

    final managedFailure = classifyGemmaStartupFailure(
      Exception('403 forbidden while requesting model access'),
      source: managedSource,
    );
    final localFailure = classifyGemmaStartupFailure(
      const FileSystemException('missing local model'),
      source: localSource,
    );

    expect(managedFailure.kind, GemmaStartupFailureKind.modelAccess);
    expect(
        managedFailure.message.toLowerCase(), isNot(contains('hugging face')));
    expect(localFailure.kind, GemmaStartupFailureKind.localModel);
    expect(localFailure.message.toLowerCase(), contains('imported model file'));
  });

  test('Gemma startup failures classify Hugging Face token issues separately',
      () {
    const legacySource = ModelSourceConfig(
      kind: ModelSourceKind.network,
      origin: ModelSourceOrigin.legacyHuggingFace,
      location:
          'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma.task',
      label: 'Legacy Hugging Face download',
    );

    final failure = classifyGemmaStartupFailure(
      Exception('403 forbidden while requesting model access'),
      source: legacySource,
    );

    expect(failure.kind, GemmaStartupFailureKind.modelAccess);
    expect(failure.message, contains('Hugging Face'));
  });

  test('Inference failures classify timeout and backend issues', () {
    expect(
      classifyInferenceFailure(
        TimeoutException('generation timed out'),
      ).kind,
      InferenceFailureKind.timeout,
    );
    expect(
      classifyInferenceFailure(
        Exception('CPU delegate crashed during inference'),
      ).kind,
      InferenceFailureKind.backendInitialization,
    );
  });

  test('GemmaService dispatches network installs with the resolved source',
      () async {
    final sourceService = await _createSourceService(
      configuredModelUrl: 'https://cdn.example.com/gemma.task',
      configuredToken: 'managed-token',
    );
    ModelSourceConfig? installedSource;
    final service = GemmaService(
      modelSourceService: sourceService,
      isModelInstalled: (_) async => false,
      installModel: ({
        required source,
        onProgress,
      }) async {
        installedSource = source;
        onProgress?.call(100);
      },
      createModel: (_) async => _FakeInferenceModel(),
    );
    addTearDown(service.dispose);

    final snapshot = await service.ensureReady();

    expect(installedSource, isNotNull);
    expect(installedSource!.kind, ModelSourceKind.network);
    expect(installedSource!.location, 'https://cdn.example.com/gemma.task');
    expect(installedSource!.token, 'managed-token');
    expect(snapshot.source.origin, ModelSourceOrigin.envUrl);
  });

  test('GemmaService dispatches file installs with the resolved source',
      () async {
    final sourceService = await _createSourceService(
      configuredModelPath: '/tmp/gemma.task',
    );
    ModelSourceConfig? installedSource;
    final service = GemmaService(
      modelSourceService: sourceService,
      isModelInstalled: (_) async => false,
      installModel: ({
        required source,
        onProgress,
      }) async {
        installedSource = source;
      },
      createModel: (_) async => _FakeInferenceModel(),
    );
    addTearDown(service.dispose);

    final snapshot = await service.ensureReady();

    expect(installedSource, isNotNull);
    expect(installedSource!.kind, ModelSourceKind.file);
    expect(installedSource!.location, '/tmp/gemma.task');
    expect(snapshot.source.origin, ModelSourceOrigin.envPath);
  });
}
