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
  Future<void> close() async {}
}

Future<ModelSourceService> _createSourceService({
  required PickModelFileFn pickModelFile,
  String? configuredModelUrl,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();

  return ModelSourceService(
    loadPreferences: () async => preferences,
    loadDocumentsDirectory: () async => Directory.systemTemp,
    pickModelFile: pickModelFile,
    configuredModelUrl: configuredModelUrl,
  );
}

void main() {
  test('GemmaNotifier surfaces unsupported local model imports as errors',
      () async {
    final sourceService = await _createSourceService(
      pickModelFile: () async => const PickedModelFile(
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
  });
}
