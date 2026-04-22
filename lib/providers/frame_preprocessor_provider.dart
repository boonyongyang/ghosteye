import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/frame_preprocessor.dart';
import 'inference_pipeline_metrics_provider.dart';

final framePreprocessorProvider = Provider<FramePreprocessor>((ref) {
  final settings = ref.watch(framePreprocessorSettingsProvider);
  final preprocessor = FramePreprocessor.worker(settings: settings);
  ref.onDispose(preprocessor.dispose);
  return preprocessor;
});
