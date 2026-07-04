import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/cinematic_mode.dart';
import '../models/onboarding_status.dart';
import '../models/script_entry.dart';
import '../providers/camera_provider.dart';
import '../providers/cinematic_mode_provider.dart';
import '../providers/gemma_provider.dart';
import '../providers/inference_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/session_controls_provider.dart';
import '../providers/script_provider.dart';
import '../services/app_haptics.dart';
import '../services/camera_service.dart';
import '../widgets/camera_preview.dart';
import '../widgets/cinematic_mode_selector.dart';
import '../widgets/director_tips_sheet.dart';
import '../widgets/inference_indicator.dart';
import '../widgets/script_export_sheet.dart';
import '../widgets/debug_metrics_sheet.dart';
import '../widgets/model_center_sheet.dart';
import '../widgets/script_history_sheet.dart';
import '../widgets/teleprompter_overlay.dart';

class DirectorScreen extends ConsumerStatefulWidget {
  const DirectorScreen({super.key});

  @override
  ConsumerState<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends ConsumerState<DirectorScreen> {
  bool _scheduledFirstRunTips = false;
  bool _showingTipsSheet = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(inferenceProvider);

    ref.listen<CinematicMode>(cinematicModeProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(_resetScene(ref));
    });

    final cameraState = ref.watch(cameraSessionViewProvider);
    final gemmaState = ref.watch(gemmaStateViewProvider).valueOrNull;
    final onboardingState = ref.watch(onboardingProvider);
    final inferenceStatus = ref.watch(inferenceStatusProvider);
    final captureEnabled = ref.watch(captureEnabledProvider);
    final reviewMode = ref.watch(reviewModeProvider);
    final scriptState = ref.watch(scriptProvider);

    _maybeShowFirstRunTips(
      cameraState: cameraState,
      onboardingState: onboardingState,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DirectorCameraPreview(cameraState: cameraState),
          const Align(
            alignment: Alignment.bottomCenter,
            child: TeleprompterOverlay(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppConstants.appTitle.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Live screenplay in your pocket.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      InferenceIndicator(
                        status: inferenceStatus,
                        captureEnabled: captureEnabled,
                        isDegraded: gemmaState?.usedFallback ?? false,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!captureEnabled && reviewMode) ...<Widget>[
                    const _ReviewModeBanner(),
                    const SizedBox(height: 8),
                  ],
                  _DirectorActions(
                    captureEnabled: captureEnabled,
                    onToggleCapture: () => captureEnabled
                        ? unawaited(_pauseCapture(ref))
                        : _resumeCapture(ref),
                    onClearScript: () => unawaited(_resetScene(ref)),
                    onShowHistory: () =>
                        unawaited(_showHistorySheet(context, ref)),
                    onShowExport: () => unawaited(
                      _showExportSheet(
                        context,
                        title: 'Current take',
                        entries: scriptState.entries,
                        capturedAt: scriptState.activeSessionStartedAt,
                      ),
                    ),
                    onShowTips: () => unawaited(_showDirectorTips()),
                    onShowModelCenter: () =>
                        unawaited(_showModelCenterSheet(context, ref)),
                  ),
                  const SizedBox(height: 12),
                  if (kDebugMode)
                    Center(
                      child: GestureDetector(
                        onTap: () => unawaited(
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const DebugMetricsSheet(),
                          ),
                        ),
                        child: const _DebugBadge(label: 'DEV METRICS'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: CinematicModeSelector(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _maybeShowFirstRunTips({
    required AsyncValue<CameraSession> cameraState,
    required AsyncValue<OnboardingStatus> onboardingState,
  }) {
    if (_scheduledFirstRunTips || _showingTipsSheet) {
      return;
    }

    final onboarding = onboardingState.valueOrNull;
    final cameraSession = cameraState.valueOrNull;
    final cameraReady =
        cameraSession != null && cameraSession.controller.value.isInitialized;

    if (onboarding == null || onboarding.directorTipsSeen || !cameraReady) {
      return;
    }

    _scheduledFirstRunTips = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_showDirectorTips(firstRun: true));
    });
  }

  Future<void> _showDirectorTips({bool firstRun = false}) async {
    if (_showingTipsSheet) {
      return;
    }

    _showingTipsSheet = true;
    final wasCaptureEnabled = ref.read(captureEnabledProvider);
    if (wasCaptureEnabled) {
      await _pauseCapture(ref);
    }
    if (!mounted) {
      _showingTipsSheet = false;
      return;
    }

    final primaryLabel = firstRun
        ? 'Start shooting'
        : wasCaptureEnabled
            ? 'Back to scene'
            : 'Close tips';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !firstRun,
      enableDrag: !firstRun,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.74,
          child: DirectorTipsSheet(
            primaryLabel: primaryLabel,
            onPrimaryPressed: () {
              Navigator.of(sheetContext).pop();
            },
          ),
        );
      },
    );

    if (firstRun) {
      await ref.read(onboardingProvider.notifier).markDirectorTipsSeen();
    }
    if (wasCaptureEnabled && mounted) {
      _resumeCapture(ref);
    }
    _showingTipsSheet = false;
  }
}

Future<void> _pauseCapture(WidgetRef ref) async {
  ref.read(captureEnabledProvider.notifier).state = false;
  await _interruptGeneration(ref);
  _setStatusAfterSceneReset(ref);
}

void _resumeCapture(WidgetRef ref) {
  ref.read(reviewModeProvider.notifier).state = false;
  ref.read(captureEnabledProvider.notifier).state = true;
  final previousStatus = ref.read(inferenceStatusProvider);
  ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
    activity: InferenceActivity.idle,
    lastInferenceDuration: previousStatus.lastInferenceDuration,
  );
}

Future<void> _resetScene(WidgetRef ref) async {
  ref.read(reviewModeProvider.notifier).state = false;
  await _interruptGeneration(ref);
  ref.read(scriptProvider.notifier).clear();
  await ref.read(gemmaProvider.notifier).resetConversation();
  _setStatusAfterSceneReset(ref);
}

Future<void> _interruptGeneration(WidgetRef ref) async {
  await ref.read(gemmaProvider.notifier).cancelGeneration();
  ref.read(scriptProvider.notifier).cancelActiveResponse();
  ref.read(cameraProvider.notifier).completeInference();
}

Future<void> _showModelCenterSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return ModelCenterSheet(
        onResetCachedInstall: () {
          Navigator.of(context).pop();
          ref.read(gemmaProvider.notifier).resetCachedInstall();
        },
        onImportLocalModel: () async {
          Navigator.of(context).pop();
          await ref.read(gemmaProvider.notifier).importLocalModel();
        },
        onUseConfiguredSource: () async {
          Navigator.of(context).pop();
          await ref.read(gemmaProvider.notifier).useManagedDownload();
        },
      );
    },
  );
}

Future<void> _showHistorySheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.78,
        child: ScriptHistorySheet(
          onSelectSession: (session) async {
            Navigator.of(sheetContext).pop();
            await _pauseCapture(ref);
            ref.read(scriptProvider.notifier).loadSessionForReview(session);
            ref.read(reviewModeProvider.notifier).state = true;
          },
          onExportSession: (session) async {
            Navigator.of(sheetContext).pop();
            await _showExportSheet(
              context,
              title: 'Saved take',
              entries: session.entries,
              capturedAt: session.updatedAt,
              notes: session.notes,
            );
          },
        ),
      );
    },
  );
}

Future<void> _showExportSheet(
  BuildContext context, {
  required String title,
  required List<ScriptEntry> entries,
  DateTime? capturedAt,
  String notes = '',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.68,
        child: ScriptExportSheet(
          title: title,
          entries: entries,
          capturedAt: capturedAt,
          notes: notes,
        ),
      );
    },
  );
}

void _setStatusAfterSceneReset(WidgetRef ref) {
  final previousStatus = ref.read(inferenceStatusProvider);
  final captureEnabled = ref.read(captureEnabledProvider);
  ref.read(inferenceStatusProvider.notifier).state = InferenceStatusState(
    activity:
        captureEnabled ? InferenceActivity.idle : InferenceActivity.paused,
    lastInferenceDuration: previousStatus.lastInferenceDuration,
  );
}

class _DirectorActions extends StatelessWidget {
  const _DirectorActions({
    required this.captureEnabled,
    required this.onToggleCapture,
    required this.onClearScript,
    required this.onShowHistory,
    required this.onShowExport,
    required this.onShowTips,
    required this.onShowModelCenter,
  });

  final bool captureEnabled;
  final VoidCallback onToggleCapture;
  final VoidCallback onClearScript;
  final VoidCallback onShowHistory;
  final VoidCallback onShowExport;
  final VoidCallback onShowTips;
  final VoidCallback onShowModelCenter;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.38),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _CaptureToggleButton(
                        captureEnabled: captureEnabled,
                        onTap: onToggleCapture,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _DockAction(
                      icon: Icons.layers_clear_outlined,
                      label: 'Clear',
                      onTap: onClearScript,
                      hapticPattern: AppHapticPattern.emphasis,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _DockAction(
                        icon: Icons.history_toggle_off_outlined,
                        label: 'History',
                        onTap: onShowHistory,
                        hapticPattern: AppHapticPattern.selection,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DockAction(
                        icon: Icons.ios_share_outlined,
                        label: 'Export',
                        onTap: onShowExport,
                        hapticPattern: AppHapticPattern.selection,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DockAction(
                        icon: Icons.lightbulb_outline,
                        label: 'Tips',
                        onTap: onShowTips,
                        hapticPattern: AppHapticPattern.selection,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DockAction(
                        icon: Icons.tune_outlined,
                        label: 'Settings',
                        onTap: onShowModelCenter,
                        hapticPattern: AppHapticPattern.selection,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureToggleButton extends StatelessWidget {
  const _CaptureToggleButton({
    required this.captureEnabled,
    required this.onTap,
  });

  final bool captureEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon =
        captureEnabled ? Icons.pause_circle_outline : Icons.play_circle_outline;
    final label = captureEnabled ? 'Pause' : 'Resume';
    final detail = captureEnabled ? 'Capture is live' : 'Capture is paused';

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          AppHaptics.trigger(AppHapticPattern.action);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 24, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.hapticPattern,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppHapticPattern hapticPattern;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          AppHaptics.trigger(hapticPattern);
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 10,
            vertical: compact ? 13 : 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewModeBanner extends StatelessWidget {
  const _ReviewModeBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2B95C).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFF2B95C).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.movie_outlined,
                size: 13,
                color: Color(0xFFF2B95C),
              ),
              const SizedBox(width: 6),
              Text(
                'REVIEWING SAVED TAKE',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF2B95C),
                      letterSpacing: 1.0,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugBadge extends StatelessWidget {
  const _DebugBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
