import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/model_source.dart';

typedef LoadPreferencesFn = Future<SharedPreferences> Function();
typedef LoadDocumentsDirectoryFn = Future<Directory> Function();
typedef PickModelFileFn = Future<PickedModelFile?> Function();

class NoModelSourceConfiguredException implements Exception {
  const NoModelSourceConfiguredException();

  static const message =
      'Ghosteye needs a managed model download URL or a local model file before setup can continue.';

  @override
  String toString() => message;
}

class PickedModelFile {
  const PickedModelFile({
    required this.path,
    required this.name,
  });

  final String path;
  final String name;
}

class ModelSourceService {
  ModelSourceService({
    LoadPreferencesFn? loadPreferences,
    LoadDocumentsDirectoryFn? loadDocumentsDirectory,
    PickModelFileFn? pickModelFile,
    String? configuredModelPath,
    String? configuredModelUrl,
    String? configuredToken,
  })  : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance,
        _loadDocumentsDirectory =
            loadDocumentsDirectory ?? getApplicationDocumentsDirectory,
        _pickModelFile = pickModelFile ?? _defaultPickModelFile,
        _configuredModelPath =
            configuredModelPath ?? AppConstants.configuredModelPath,
        _configuredModelUrl =
            configuredModelUrl ?? AppConstants.configuredModelUrl,
        _configuredToken = configuredToken ?? AppConstants.modelAccessToken;

  static const importedModelPathKey = 'ghosteye.imported_model_path';
  static const installedSourceSignatureKey =
      'ghosteye.installed_model_source_signature';
  static const importDirectoryName = 'imported_models';
  static const supportedModelExtensions = <String>{
    'task',
    'litertlm',
    'bin',
    'tflite',
  };

  final LoadPreferencesFn _loadPreferences;
  final LoadDocumentsDirectoryFn _loadDocumentsDirectory;
  final PickModelFileFn _pickModelFile;
  final String? _configuredModelPath;
  final String? _configuredModelUrl;
  final String? _configuredToken;

  Future<ModelSourceConfig> resolveSource() async {
    final preferences = await _loadPreferences();
    final importedPath = preferences.getString(importedModelPathKey);
    if (importedPath != null && importedPath.isNotEmpty) {
      return ModelSourceConfig(
        kind: ModelSourceKind.file,
        origin: ModelSourceOrigin.importedFile,
        location: importedPath,
        label: 'Imported local model',
      );
    }

    if (_configuredModelPath case final configuredPath?
        when configuredPath.isNotEmpty) {
      return ModelSourceConfig(
        kind: ModelSourceKind.file,
        origin: ModelSourceOrigin.envPath,
        location: configuredPath,
        label: 'Configured local model',
      );
    }

    if (_configuredModelUrl case final configuredUrl?
        when configuredUrl.isNotEmpty) {
      return ModelSourceConfig(
        kind: ModelSourceKind.network,
        origin: ModelSourceOrigin.envUrl,
        location: configuredUrl,
        label: 'Managed download',
        token: _configuredToken,
      );
    }

    throw const NoModelSourceConfiguredException();
  }

  Future<String?> loadInstalledSourceSignature() async {
    final preferences = await _loadPreferences();
    return preferences.getString(installedSourceSignatureKey);
  }

  Future<void> saveInstalledSourceSignature(ModelSourceConfig source) async {
    final preferences = await _loadPreferences();
    await preferences.setString(installedSourceSignatureKey, source.signature);
  }

  Future<void> clearInstalledSourceSignature() async {
    final preferences = await _loadPreferences();
    await preferences.remove(installedSourceSignatureKey);
  }

  Future<ModelSourceConfig?> importLocalModel() async {
    final pickedModel = await _pickModelFile();
    if (pickedModel == null) {
      return null;
    }

    if (!isSupportedModelFileName(pickedModel.name)) {
      throw ArgumentError(
        'Unsupported model file type. Choose a .task, .litertlm, .bin, or .tflite file.',
      );
    }

    final sourceFile = File(pickedModel.path);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'The selected model file could not be found.',
        pickedModel.path,
      );
    }

    final documentsDirectory = await _loadDocumentsDirectory();
    final importDirectory = Directory(
      '${documentsDirectory.path}/$importDirectoryName',
    );
    await importDirectory.create(recursive: true);

    final cleanedName = _sanitizeFileName(pickedModel.name);
    final importedPath =
        '${importDirectory.path}/imported-${DateTime.now().millisecondsSinceEpoch}-$cleanedName';
    await sourceFile.copy(importedPath);

    final preferences = await _loadPreferences();
    final previousImportedPath = preferences.getString(importedModelPathKey);
    await preferences.setString(importedModelPathKey, importedPath);

    if (previousImportedPath != null &&
        previousImportedPath.isNotEmpty &&
        previousImportedPath != importedPath) {
      final previousFile = File(previousImportedPath);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    return ModelSourceConfig(
      kind: ModelSourceKind.file,
      origin: ModelSourceOrigin.importedFile,
      location: importedPath,
      label: 'Imported local model',
    );
  }

  Future<void> clearImportedModel() async {
    final preferences = await _loadPreferences();
    final importedPath = preferences.getString(importedModelPathKey);
    await preferences.remove(importedModelPathKey);

    if (importedPath == null || importedPath.isEmpty) {
      return;
    }

    final importedFile = File(importedPath);
    if (await importedFile.exists()) {
      await importedFile.delete();
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  static bool isSupportedModelFileName(String fileName) {
    final separatorIndex = fileName.lastIndexOf('.');
    if (separatorIndex == -1 || separatorIndex == fileName.length - 1) {
      return false;
    }

    final extension = fileName.substring(separatorIndex + 1).toLowerCase();
    return supportedModelExtensions.contains(extension);
  }

  static Future<PickedModelFile?> _defaultPickModelFile() async {
    final selectedFile = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'Gemma model files',
          uniformTypeIdentifiers: <String>['public.data'],
        ),
      ],
      confirmButtonText: 'Import',
    );
    if (selectedFile == null) {
      return null;
    }

    final filePath = selectedFile.path;
    if (filePath.isEmpty) {
      return null;
    }

    return PickedModelFile(
      path: filePath,
      name: selectedFile.name,
    );
  }
}
