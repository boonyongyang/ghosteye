import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teleprompter_settings.dart';

final teleprompterSettingsProvider =
    NotifierProvider<TeleprompterSettingsController, TeleprompterSettings>(
  TeleprompterSettingsController.new,
);

class TeleprompterSettingsController extends Notifier<TeleprompterSettings> {
  @override
  TeleprompterSettings build() => const TeleprompterSettings();

  void setTextSize(TeleprompterTextSize textSize) {
    state = state.copyWith(textSize: textSize);
  }

  void setDensity(TeleprompterDensity density) {
    state = state.copyWith(density: density);
  }

  void setPace(TeleprompterPace pace) {
    state = state.copyWith(pace: pace);
  }
}
