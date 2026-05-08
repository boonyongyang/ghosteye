import 'package:flutter/material.dart';

enum AppStatus { ready, needsAction, working, degraded, failed }

extension AppStatusVisuals on AppStatus {
  Color color(BuildContext context) => switch (this) {
        AppStatus.ready => const Color(0xFF4DD08A),
        AppStatus.working => Theme.of(context).colorScheme.primary,
        AppStatus.needsAction => const Color(0xFFF2B95C),
        AppStatus.degraded => const Color(0xFFF2B95C),
        AppStatus.failed => Theme.of(context).colorScheme.error,
      };

  IconData get icon => switch (this) {
        AppStatus.ready => Icons.check_circle_outline,
        AppStatus.working => Icons.auto_awesome_motion_outlined,
        AppStatus.needsAction => Icons.info_outline,
        AppStatus.degraded => Icons.warning_amber_outlined,
        AppStatus.failed => Icons.error_outline,
      };
}
