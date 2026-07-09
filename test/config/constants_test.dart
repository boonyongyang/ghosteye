import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/constants.dart';

void main() {
  group('AppConstants.modelIdFromLocation', () {
    test('returns the last path segment of a managed URL', () {
      expect(
        AppConstants.modelIdFromLocation(
          'https://cdn.example.com/models/gemma-3n-E2B-it-int4.task',
        ),
        equals('gemma-3n-E2B-it-int4.task'),
      );
    });

    test('returns the file name of an absolute unix path', () {
      expect(
        AppConstants.modelIdFromLocation('/var/models/gemma.litertlm'),
        equals('gemma.litertlm'),
      );
    });

    test('returns a bare file name unchanged', () {
      expect(
        AppConstants.modelIdFromLocation('model.task'),
        equals('model.task'),
      );
    });

    test('falls back to the default file name for an empty location', () {
      expect(
        AppConstants.modelIdFromLocation(''),
        equals(AppConstants.defaultModelFileName),
      );
    });
  });

  group('AppConstants compile-time defaults (no dart-define)', () {
    test('frame preprocessor backend defaults to ffi', () {
      expect(AppConstants.configuredFramePreprocessorBackend, equals('ffi'));
    });

    test('frame max dimension defaults to the model input dimension', () {
      expect(
        AppConstants.configuredFrameMaxDimension,
        equals(AppConstants.modelInputMaxDimension),
      );
    });

    test('frame JPEG quality defaults to the constant', () {
      expect(
        AppConstants.configuredFrameJpegQuality,
        equals(AppConstants.frameJpegQuality),
      );
    });

    test('no model URL, path, or token are configured by default', () {
      expect(AppConstants.configuredModelUrl, isNull);
      expect(AppConstants.configuredModelPath, isNull);
      expect(AppConstants.modelAccessToken, isNull);
    });
  });
}
