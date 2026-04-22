import 'dart:async';

import 'package:flutter/services.dart';

enum AppHapticPattern {
  selection,
  action,
  emphasis,
}

class AppHaptics {
  const AppHaptics._();

  static void trigger(AppHapticPattern pattern) {
    final future = switch (pattern) {
      AppHapticPattern.selection => HapticFeedback.selectionClick(),
      AppHapticPattern.action => HapticFeedback.lightImpact(),
      AppHapticPattern.emphasis => HapticFeedback.mediumImpact(),
    };

    unawaited(
      future.catchError((Object _, StackTrace __) {}),
    );
  }
}
