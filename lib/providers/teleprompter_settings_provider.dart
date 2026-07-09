import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teleprompter_settings.dart';
import 'preferences_provider.dart';

final teleprompterSettingsProvider =
    NotifierProvider<TeleprompterSettingsController, TeleprompterSettings>(
  TeleprompterSettingsController.new,
);

class TeleprompterSettingsController extends Notifier<TeleprompterSettings> {
  static const _textSizeKey = 'ghosteye.teleprompter_text_size';
  static const _densityKey = 'ghosteye.teleprompter_density';
  static const _paceKey = 'ghosteye.teleprompter_pace';

  @override
  TeleprompterSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) {
      return const TeleprompterSettings();
    }
    const defaults = TeleprompterSettings();
    return TeleprompterSettings(
      textSize: readPersistedEnum(
        prefs.getString(_textSizeKey),
        TeleprompterTextSize.values,
        defaults.textSize,
      ),
      density: readPersistedEnum(
        prefs.getString(_densityKey),
        TeleprompterDensity.values,
        defaults.density,
      ),
      pace: readPersistedEnum(
        prefs.getString(_paceKey),
        TeleprompterPace.values,
        defaults.pace,
      ),
    );
  }

  void setTextSize(TeleprompterTextSize textSize) {
    state = state.copyWith(textSize: textSize);
    ref.read(sharedPreferencesProvider)?.setString(_textSizeKey, textSize.name);
  }

  void setDensity(TeleprompterDensity density) {
    state = state.copyWith(density: density);
    ref.read(sharedPreferencesProvider)?.setString(_densityKey, density.name);
  }

  void setPace(TeleprompterPace pace) {
    state = state.copyWith(pace: pace);
    ref.read(sharedPreferencesProvider)?.setString(_paceKey, pace.name);
  }
}
