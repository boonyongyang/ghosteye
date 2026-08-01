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
    final preferences = ref.read(sharedPreferencesProvider);
    const defaults = TeleprompterSettings();
    if (preferences == null) {
      return defaults;
    }

    return TeleprompterSettings(
      textSize: readPersistedEnum(
        preferences.getString(_textSizeKey),
        TeleprompterTextSize.values,
        defaults.textSize,
      ),
      density: readPersistedEnum(
        preferences.getString(_densityKey),
        TeleprompterDensity.values,
        defaults.density,
      ),
      pace: readPersistedEnum(
        preferences.getString(_paceKey),
        TeleprompterPace.values,
        defaults.pace,
      ),
    );
  }

  void setTextSize(TeleprompterTextSize value) {
    state = state.copyWith(textSize: value);
    ref.read(sharedPreferencesProvider)?.setString(_textSizeKey, value.name);
  }

  void setDensity(TeleprompterDensity value) {
    state = state.copyWith(density: value);
    ref.read(sharedPreferencesProvider)?.setString(_densityKey, value.name);
  }

  void setPace(TeleprompterPace value) {
    state = state.copyWith(pace: value);
    ref.read(sharedPreferencesProvider)?.setString(_paceKey, value.name);
  }
}
