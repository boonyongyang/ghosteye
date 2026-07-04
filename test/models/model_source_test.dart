import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/model_source.dart';

ModelSourceConfig _config({
  ModelSourceKind kind = ModelSourceKind.network,
  ModelSourceOrigin origin = ModelSourceOrigin.envUrl,
  String location = 'https://cdn.example.com/models/gemma.task',
  String label = 'Managed download',
  String? token,
}) {
  return ModelSourceConfig(
    kind: kind,
    origin: origin,
    location: location,
    label: label,
    token: token,
  );
}

void main() {
  group('ModelSourceConfig kind flags', () {
    test('isNetwork and isFile reflect the kind', () {
      expect(_config(kind: ModelSourceKind.network).isNetwork, isTrue);
      expect(_config(kind: ModelSourceKind.network).isFile, isFalse);
      expect(_config(kind: ModelSourceKind.file).isFile, isTrue);
      expect(_config(kind: ModelSourceKind.file).isNetwork, isFalse);
    });

    test('isImportedFile reflects the origin', () {
      expect(
        _config(origin: ModelSourceOrigin.importedFile).isImportedFile,
        isTrue,
      );
      expect(_config(origin: ModelSourceOrigin.envUrl).isImportedFile, isFalse);
      expect(_config(origin: ModelSourceOrigin.envPath).isImportedFile, isFalse);
    });
  });

  group('ModelSourceConfig.isHuggingFace', () {
    test('is true only when the location points at huggingface.co', () {
      expect(
        _config(
          location:
              'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/model.task',
        ).isHuggingFace,
        isTrue,
      );
      expect(
        _config(location: 'https://cdn.example.com/model.task').isHuggingFace,
        isFalse,
      );
    });
  });

  group('ModelSourceConfig.modelId', () {
    test('derives the model id from the location file name', () {
      expect(
        _config(location: 'https://cdn.example.com/models/gemma.litertlm')
            .modelId,
        equals('gemma.litertlm'),
      );
    });
  });

  group('ModelSourceConfig.signature', () {
    test('combines origin name and location', () {
      final config = _config(
        origin: ModelSourceOrigin.importedFile,
        location: '/data/model.task',
      );
      expect(config.signature, equals('importedFile:/data/model.task'));
    });

    test('changes when the source origin or location changes', () {
      final a = _config(origin: ModelSourceOrigin.envUrl, location: 'a');
      final b = _config(origin: ModelSourceOrigin.envPath, location: 'a');
      final c = _config(origin: ModelSourceOrigin.envUrl, location: 'b');

      expect(a.signature, isNot(equals(b.signature)));
      expect(a.signature, isNot(equals(c.signature)));
    });
  });
}
