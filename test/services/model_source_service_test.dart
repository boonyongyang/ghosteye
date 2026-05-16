import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/model_source.dart';
import 'package:ghosteye/services/model_source_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ModelSourceService> _createService({
  required SharedPreferences preferences,
  required Directory documentsDirectory,
  PickModelFileFn? pickModelFile,
  String? configuredModelPath,
  String? configuredModelUrl,
  String? configuredToken,
}) async {
  return ModelSourceService(
    loadPreferences: () async => preferences,
    loadDocumentsDirectory: () async => documentsDirectory,
    pickModelFile: pickModelFile ?? () async => null,
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

  test('resolveSource prefers persisted imported model path', () async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{
        ModelSourceService.importedModelPathKey: '/tmp/imported.task',
      },
    );
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
      configuredModelPath: '/env/model.task',
      configuredModelUrl: 'https://cdn.example.com/model.task',
      configuredToken: 'token',
    );

    final source = await service.resolveSource();

    expect(source.origin, ModelSourceOrigin.importedFile);
    expect(source.kind, ModelSourceKind.file);
    expect(source.location, '/tmp/imported.task');
  });

  test('resolveSource prefers configured model path over managed URL',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
      configuredModelPath: '/env/model.task',
      configuredModelUrl: 'https://cdn.example.com/model.task',
    );

    final source = await service.resolveSource();

    expect(source.origin, ModelSourceOrigin.envPath);
    expect(source.kind, ModelSourceKind.file);
    expect(source.location, '/env/model.task');
  });

  test(
      'resolveSource uses configured managed download URL when no local path is set',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
      configuredModelUrl: 'https://cdn.example.com/model.task',
      configuredToken: 'managed-token',
    );

    final source = await service.resolveSource();

    expect(source.origin, ModelSourceOrigin.envUrl);
    expect(source.kind, ModelSourceKind.network);
    expect(source.location, 'https://cdn.example.com/model.task');
    expect(source.token, 'managed-token');
  });

  test('resolveSource throws when no model source is configured', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
    );

    await expectLater(
      service.resolveSource(),
      throwsA(isA<NoModelSourceConfiguredException>()),
    );
  });

  test('importLocalModel copies the file and persists the imported path',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'ghosteye-model-source-docs',
    );
    addTearDown(() async {
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final sourceFile = File('${documentsDirectory.path}/source-model.task');
    await sourceFile.writeAsString('fake model');

    final service = await _createService(
      preferences: preferences,
      documentsDirectory: documentsDirectory,
      pickModelFile: () async => PickedModelFile(
        path: sourceFile.path,
        name: 'source-model.task',
      ),
    );

    final importedSource = await service.importLocalModel();
    final persistedPath =
        preferences.getString(ModelSourceService.importedModelPathKey);

    expect(importedSource, isNotNull);
    expect(importedSource!.origin, ModelSourceOrigin.importedFile);
    expect(importedSource.kind, ModelSourceKind.file);
    expect(persistedPath, importedSource.location);
    expect(await File(importedSource.location).exists(), isTrue);

    await service.clearImportedModel();

    expect(
      preferences.getString(ModelSourceService.importedModelPathKey),
      isNull,
    );
    expect(await File(importedSource.location).exists(), isFalse);
  });

  test('importLocalModel returns null when the picker is canceled', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
      pickModelFile: () async => null,
    );

    final importedSource = await service.importLocalModel();

    expect(importedSource, isNull);
    expect(
      preferences.getString(ModelSourceService.importedModelPathKey),
      isNull,
    );
  });

  test('clearInstalledSourceSignature removes the persisted signature',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ModelSourceService.installedSourceSignatureKey: 'some-signature',
    });
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
    );

    expect(
      preferences.getString(ModelSourceService.installedSourceSignatureKey),
      'some-signature',
    );

    await service.clearInstalledSourceSignature();

    expect(
      preferences.getString(ModelSourceService.installedSourceSignatureKey),
      isNull,
    );
  });

  test('importLocalModel rejects unsupported file extensions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(
      preferences: preferences,
      documentsDirectory: Directory.systemTemp,
      pickModelFile: () async => const PickedModelFile(
        path: '/tmp/not-a-model.txt',
        name: 'not-a-model.txt',
      ),
    );

    await expectLater(
      service.importLocalModel(),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('.task'),
        ),
      ),
    );
  });
}
