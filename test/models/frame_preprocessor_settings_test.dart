import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/frame_preprocessor_settings.dart';

void main() {
  const base = FramePreprocessorSettings(
    backend: FramePreprocessorBackend.ffi,
    maxDimension: 768,
    jpegQuality: 88,
  );

  group('FramePreprocessorSettings.copyWith', () {
    test('replaces only the field supplied', () {
      final swapped = base.copyWith(backend: FramePreprocessorBackend.dart);

      expect(swapped.backend, equals(FramePreprocessorBackend.dart));
      expect(swapped.maxDimension, equals(base.maxDimension));
      expect(swapped.jpegQuality, equals(base.jpegQuality));
    });

    test('keeps every field when nothing is supplied', () {
      final same = base.copyWith();

      expect(same.backend, equals(base.backend));
      expect(same.maxDimension, equals(base.maxDimension));
      expect(same.jpegQuality, equals(base.jpegQuality));
    });

    test('can change the numeric tuning independently', () {
      final tuned = base.copyWith(maxDimension: 512, jpegQuality: 75);

      expect(tuned.backend, equals(base.backend));
      expect(tuned.maxDimension, equals(512));
      expect(tuned.jpegQuality, equals(75));
    });
  });

  group('FramePreprocessorSettings.fromEnvironment', () {
    test('defaults to the FFI backend with the configured tuning', () {
      // No --dart-define overrides are set under `flutter test`, so this
      // exercises the shipped defaults.
      final settings = FramePreprocessorSettings.fromEnvironment();

      expect(settings.backend, equals(FramePreprocessorBackend.ffi));
      expect(settings.maxDimension, greaterThan(0));
      expect(settings.jpegQuality, inInclusiveRange(1, 100));
    });
  });
}
