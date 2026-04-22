import '../config/constants.dart';

enum FramePreprocessorBackend {
  dart,
  ffi,
}

class FramePreprocessorSettings {
  const FramePreprocessorSettings({
    required this.backend,
    required this.maxDimension,
    required this.jpegQuality,
  });

  factory FramePreprocessorSettings.fromEnvironment() {
    return FramePreprocessorSettings(
      backend: switch (AppConstants.configuredFramePreprocessorBackend) {
        'ffi' => FramePreprocessorBackend.ffi,
        _ => FramePreprocessorBackend.dart,
      },
      maxDimension: AppConstants.configuredFrameMaxDimension,
      jpegQuality: AppConstants.configuredFrameJpegQuality,
    );
  }

  final FramePreprocessorBackend backend;
  final int maxDimension;
  final int jpegQuality;

  FramePreprocessorSettings copyWith({
    FramePreprocessorBackend? backend,
    int? maxDimension,
    int? jpegQuality,
  }) {
    return FramePreprocessorSettings(
      backend: backend ?? this.backend,
      maxDimension: maxDimension ?? this.maxDimension,
      jpegQuality: jpegQuality ?? this.jpegQuality,
    );
  }
}
