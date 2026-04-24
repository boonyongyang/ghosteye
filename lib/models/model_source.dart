import '../config/constants.dart';

enum ModelSourceKind {
  network,
  file,
}

enum ModelSourceOrigin {
  importedFile,
  envPath,
  envUrl,
}

class ModelSourceConfig {
  const ModelSourceConfig({
    required this.kind,
    required this.origin,
    required this.location,
    required this.label,
    this.token,
  });

  final ModelSourceKind kind;
  final ModelSourceOrigin origin;
  final String location;
  final String label;
  final String? token;

  bool get isNetwork => kind == ModelSourceKind.network;
  bool get isFile => kind == ModelSourceKind.file;

  bool get isImportedFile => origin == ModelSourceOrigin.importedFile;

  bool get isHuggingFace => location.contains('huggingface.co');

  String get modelId => AppConstants.modelIdFromLocation(location);

  String get signature => '${origin.name}:$location';
}
