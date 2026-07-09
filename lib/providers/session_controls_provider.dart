import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/performance_preset.dart';
import 'preferences_provider.dart';

final captureEnabledProvider = StateProvider<bool>((ref) {
  return true;
});

final reviewModeProvider = StateProvider<bool>((ref) {
  return false;
});

final performancePresetProvider =
    NotifierProvider<PerformancePresetController, PerformancePreset>(
  PerformancePresetController.new,
);

class PerformancePresetController extends Notifier<PerformancePreset> {
  static const _key = 'ghosteye.performance_preset';

  @override
  PerformancePreset build() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) {
      return PerformancePreset.balanced;
    }
    return readPersistedEnum(
      prefs.getString(_key),
      PerformancePreset.values,
      PerformancePreset.balanced,
    );
  }

  void setPreset(PerformancePreset preset) {
    state = preset;
    ref.read(sharedPreferencesProvider)?.setString(_key, preset.name);
  }
}
