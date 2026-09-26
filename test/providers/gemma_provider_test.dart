import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/services/gemma_service.dart';
import 'package:ghosteye/services/model_source_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInferenceModel extends InferenceModel {
  InferenceChat? _chat;

  @override
  InferenceChat? get chat => _chat;

  @override
  set chat(InferenceChat? value) => _chat = value;

  @override
  ModelFileType get fileType => ModelFileType.task;

  @override
  int get maxTokens => 512;

  @override
  PreferredBackend? get activeBackend => null;

  @override
  InferenceModelSession? get session => null;

  @override
  Future<InferenceModelSession> createSession({
    bool? enableAudioModality,
    bool enableThinking = false,
    double temperature = .8,
    int randomSeed = 1,
    int topK = 1,
    double? topP,
    String? systemInstruction,
    List<Tool> tools = const [],
    String? loraPath,
    bool? enableVisionModality,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}
}

Future<ModelSourceService> _createSourceService({
  required PickModelFileFn pickModelFile,
  String? configuredModelUrl,
  String? configuredToken,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();

  return ModelSourceService(
    loadPreferences: () async => preferences,
    loadDocumentsDirectory: () async => Directory.systemTemp,
    pickModelFile: pickModelFile,
    configuredModelUrl: configuredModelUrl,
    configuredToken: configuredToken,
  );
}

void main() {
  test(
    'GemmaNotifier surfaces unsupported local model imports as errors',
    () async {
      final sourceService = await _createSourceService(
        pickModelFile:
            () async => const PickedModelFile(
              path: '/tmp/not-a-model.txt',
              name: 'not-a-model.txt',
            ),
      );
      final gemmaService = GemmaService(
        modelSourceService: sourceService,
        isModelInstalled: (_) async => true,
        createModel: (_) async => _FakeInferenceModel(),
      );
      final container = ProviderContainer(
        overrides: <Override>[
          gemmaServiceProvider.overrideWithValue(gemmaService),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(gemmaService.dispose);

      await container.read(gemmaProvider.future);
      await container.read(gemmaProvider.notifier).importLocalModel();

      final state = container.read(gemmaProvider).valueOrNull;
      expect(state, isNotNull);
      expect(state!.phase, GemmaPhase.error);
      expect(state.failureKind, GemmaStartupFailureKind.localModel);
      expect(state.message, contains('.task'));
      expect(state.diagnosticDetail, isNotNull);
      expect(state.diagnosticDetail, isNotEmpty);
    },
  );

  test('GemmaNotifier surfaces missing model source configuration', () async {
    final sourceService = await _createSourceService(
      pickModelFile: () async => null,
    );
    final gemmaService = GemmaService(
      modelSourceService: sourceService,
      isModelInstalled: (_) async => true,
      createModel: (_) async => _FakeInferenceModel(),
    );
    final container = ProviderContainer(
      overrides: <Override>[
        gemmaServiceProvider.overrideWithValue(gemmaService),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(gemmaService.dispose);

    await container.read(gemmaProvider.future);
    await container.read(gemmaProvider.notifier).ensureReady();

    final state = container.read(gemmaProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state!.phase, GemmaPhase.error);
    expect(state.failureKind, GemmaStartupFailureKind.modelSource);
    expect(state.message, contains('managed model download URL'));
  });

  test('a managed-download failure never leaks the URL or token into the '
      'copyable diagnostic detail', () async {
    const url = 'https://models.example.test/gemma-4-E2B-it.litertlm';
    const token = 'hf_exampleTokenValue0123456789';

    final sourceService = await _createSourceService(
      pickModelFile: () async => null,
      configuredModelUrl: url,
      configuredToken: token,
    );
    final gemmaService = GemmaService(
      modelSourceService: sourceService,
      isModelInstalled: (_) async => false,
      installModel: ({required source, onProgress}) async {},
      // Stand in for a plugin error that echoes the request back at us.
      createModel:
          (_) async =>
              throw Exception('init failed for $url (Bearer $token)'),
    );
    final container = ProviderContainer(
      overrides: <Override>[
        gemmaServiceProvider.overrideWithValue(gemmaService),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(gemmaService.dispose);

    await container.read(gemmaProvider.future);
    await container.read(gemmaProvider.notifier).ensureReady();

    final state = container.read(gemmaProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state!.phase, GemmaPhase.error);

    final detail = state.diagnosticDetail;
    expect(detail, isNotNull);
    expect(detail, isNot(contains(token)));
    expect(detail, isNot(contains(url)));
    expect(detail, contains(redactedTokenPlaceholder));
    expect(detail, contains(redactedUrlPlaceholder));
    // Still useful to support: the underlying failure text survives.
    expect(detail, contains('init failed'));
  });
}
