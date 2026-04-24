import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const appTitle = 'Ghosteye';
  static const appTagline = "Director's eye for on-device cinema.";
  static const brandAssetPath = 'assets/branding/ghosteye-icon-master.png';
  static const frameSampleInterval = Duration(milliseconds: 1500);
  static const slowInferenceThreshold = Duration(seconds: 3);
  static const fallbackInferenceTimeout = Duration(seconds: 30);
  static const teleprompterHeightFactor = 0.4;
  static const typewriterCharDelay = Duration(milliseconds: 35);
  static const cursorBlinkInterval = Duration(milliseconds: 500);
  static const maxSavedScriptSessions = 12;
  static const maxTokens = 512;
  static const modelInputMaxDimension = 768;
  static const frameJpegQuality = 88;
  static const metricsWindowSize = 15;
  static const maxChatExchanges = 8;
  static const maxChatHistoryCharacters = 6000;
  static const settingsUri = 'app-settings:';
  static const modelDisplayName = 'Gemma 3 Nano';
  static const defaultModelFileName = 'gemma-3n-E2B-it-int4.task';
  static const directorPromptSuffix =
      'Continue the screenplay. Describe what is happening in this new shot. '
      'Stay in character and respond in 2-4 Fountain-format lines.';

  static String? get configuredModelUrl {
    const override = String.fromEnvironment('GHOSTEYE_GEMMA_MODEL_URL');
    return override.isEmpty ? null : override;
  }

  static String? get configuredModelPath {
    const override = String.fromEnvironment('GHOSTEYE_GEMMA_MODEL_PATH');
    return override.isEmpty ? null : override;
  }

  static String get configuredFramePreprocessorBackend {
    const override = String.fromEnvironment(
      'GHOSTEYE_FRAME_PREPROCESSOR_BACKEND',
      defaultValue: 'dart',
    );
    return override.toLowerCase();
  }

  static int get configuredFrameMaxDimension {
    const override = int.fromEnvironment(
      'GHOSTEYE_FRAME_MAX_DIMENSION',
      defaultValue: modelInputMaxDimension,
    );
    return override > 0 ? override : modelInputMaxDimension;
  }

  static int get configuredFrameJpegQuality {
    const override = int.fromEnvironment(
      'GHOSTEYE_FRAME_JPEG_QUALITY',
      defaultValue: frameJpegQuality,
    );
    if (override < 1 || override > 100) {
      return frameJpegQuality;
    }
    return override;
  }

  static bool get enableFramePipelineMetrics => kDebugMode;

  static String? get modelAccessToken {
    const token = String.fromEnvironment('GHOSTEYE_GEMMA_TOKEN');
    return token.isEmpty ? null : token;
  }

  static String modelIdFromLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }

    final normalizedPath = location.replaceAll('\\', '/');
    if (normalizedPath.isEmpty) {
      return defaultModelFileName;
    }

    final lastSegment = normalizedPath.split('/').last;
    return lastSegment.isEmpty ? defaultModelFileName : lastSegment;
  }
}
