import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/performance_preset.dart';

final captureEnabledProvider = StateProvider<bool>((ref) {
  return true;
});

final reviewModeProvider = StateProvider<bool>((ref) {
  return false;
});

final performancePresetProvider = StateProvider<PerformancePreset>((ref) {
  return PerformancePreset.balanced;
});
