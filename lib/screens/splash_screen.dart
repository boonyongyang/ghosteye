import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../models/model_source.dart';
import '../providers/gemma_provider.dart';
import '../services/app_haptics.dart';
import '../services/gemma_service.dart';
import '../widgets/brand_mark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  void _startSetup() {
    if (_started) {
      return;
    }

    _started = true;
    Future<void>.microtask(ref.read(gemmaProvider.notifier).ensureReady);
  }

  void _retrySetup() {
    ref.invalidate(gemmaProvider);
    setState(() {
      _started = false;
    });
    _startSetup();
  }

  Future<void> _importLocalModel() async {
    await ref.read(gemmaProvider.notifier).importLocalModel();
  }

  Future<void> _useManagedDownload() async {
    await ref.read(gemmaProvider.notifier).useManagedDownload();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<GemmaState>>(gemmaStateViewProvider,
        (previous, next) {
      final wasReady = previous?.valueOrNull?.isReady ?? false;
      final isReady = next.valueOrNull?.isReady ?? false;
      if (!wasReady && isReady && mounted) {
        context.go('/director');
      }
    });

    final gemmaState = ref.watch(gemmaStateViewProvider);

    return Scaffold(
      body: _SetupScaffold(
        state: gemmaState,
        onRetry: _retrySetup,
        onImportLocalModel: _importLocalModel,
        onUseManagedDownload: _useManagedDownload,
      ),
    );
  }
}

class _SetupScaffold extends StatelessWidget {
  const _SetupScaffold({
    required this.state,
    required this.onRetry,
    required this.onImportLocalModel,
    required this.onUseManagedDownload,
  });

  final AsyncValue<GemmaState> state;
  final VoidCallback onRetry;
  final Future<void> Function() onImportLocalModel;
  final Future<void> Function() onUseManagedDownload;

  @override
  Widget build(BuildContext context) {
    final value = state.valueOrNull;
    final isBusy = state.isLoading || value?.phase == GemmaPhase.downloading;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF050608),
            Color(0xFF0D1118),
            Color(0xFF080A0F),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SetupHeader(),
                    const SizedBox(height: 28),
                    _SetupStage(
                      state: state,
                      onRetry: onRetry,
                      onImportLocalModel: onImportLocalModel,
                      onUseManagedDownload: value?.usesImportedModel == true
                          ? onUseManagedDownload
                          : null,
                    ),
                    const SizedBox(height: 18),
                    _SourceSummary(source: value?.source),
                    const SizedBox(height: 18),
                    _PreflightChecklist(source: value?.source),
                    if (value?.hasError != true) ...<Widget>[
                      const SizedBox(height: 18),
                      _SetupFallbackActions(
                        isBusy: isBusy,
                        usesImportedModel: value?.usesImportedModel ?? false,
                        onImportLocalModel: onImportLocalModel,
                        onUseManagedDownload: onUseManagedDownload,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const BrandMark(size: 72, radius: 18),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppConstants.appTitle,
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 6),
              Text(
                'Model setup',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'First run prepares the on-device model before Ghosteye opens the camera.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupStage extends StatelessWidget {
  const _SetupStage({
    required this.state,
    required this.onRetry,
    required this.onImportLocalModel,
    required this.onUseManagedDownload,
  });

  final AsyncValue<GemmaState> state;
  final VoidCallback onRetry;
  final Future<void> Function() onImportLocalModel;
  final Future<void> Function()? onUseManagedDownload;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (value) => value.hasError
          ? _SetupError(
              message: value.message ?? 'Unable to load model',
              failureKind: value.failureKind,
              source: value.source,
              onRetry: onRetry,
              onImportLocalModel: onImportLocalModel,
              onUseManagedDownload: onUseManagedDownload,
            )
          : _SetupProgress(state: value),
      loading: () => const _SetupProgress(state: GemmaState.idle()),
      error: (error, stackTrace) => _SetupError(
        message: error.toString(),
        onRetry: onRetry,
        onImportLocalModel: onImportLocalModel,
      ),
    );
  }
}

class _SetupProgress extends StatelessWidget {
  const _SetupProgress({required this.state});

  final GemmaState state;

  @override
  Widget build(BuildContext context) {
    final progressValue = switch (state.phase) {
      GemmaPhase.downloading => state.progress / 100,
      GemmaPhase.ready => 1.0,
      _ => null,
    };

    final label = switch (state.phase) {
      GemmaPhase.checking => 'Checking model availability',
      GemmaPhase.downloading => 'Downloading Gemma 3 Nano (${state.progress}%)',
      GemmaPhase.ready => 'Model primed. Rolling to camera.',
      GemmaPhase.error => state.message ?? 'Unable to load model',
      GemmaPhase.idle => 'Preparing setup',
    };

    final sourceDetail = switch (state.source?.kind) {
      ModelSourceKind.file when state.source?.isImportedFile ?? false =>
        'Source: imported local model. Ghosteye will reuse this copied file on later launches before opening the director view.',
      ModelSourceKind.file =>
        'Source: configured local model path. Ghosteye will prepare it locally before opening the camera.',
      ModelSourceKind.network =>
        'Source: managed download. First launch downloads a large on-device model, so Wi-Fi is recommended before camera access starts.',
      null =>
        'Choose a managed URL or import a local .task file so setup can continue.',
    };

    final detail = switch (state.phase) {
      GemmaPhase.ready when state.usedFallback =>
        'GPU setup failed, so Ghosteye switched to CPU. It should still work, but inference may feel slower.',
      GemmaPhase.ready when state.activeBackend != null =>
        '${AppConstants.modelDisplayName} is ready on ${state.activeBackend!.name.toUpperCase()} via ${state.source?.label.toLowerCase() ?? 'the active source'}.',
      _ => sourceDetail,
    };

    return _SetupPanel(
      statusColor: _statusColor(context, state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _StageLabel(
            icon: state.phase == GemmaPhase.ready
                ? Icons.check_circle_outline
                : Icons.auto_awesome_motion_outlined,
            label: label,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progressValue),
          const SizedBox(height: 14),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, GemmaState state) {
    return switch (state.phase) {
      GemmaPhase.ready => const Color(0xFF4DD08A),
      GemmaPhase.downloading ||
      GemmaPhase.checking =>
        Theme.of(context).colorScheme.primary,
      GemmaPhase.error => Theme.of(context).colorScheme.error,
      GemmaPhase.idle => Colors.white54,
    };
  }
}

class _SetupError extends StatelessWidget {
  const _SetupError({
    required this.message,
    this.failureKind,
    this.source,
    required this.onRetry,
    required this.onImportLocalModel,
    this.onUseManagedDownload,
  });

  final String message;
  final GemmaStartupFailureKind? failureKind;
  final ModelSourceConfig? source;
  final VoidCallback onRetry;
  final Future<void> Function() onImportLocalModel;
  final Future<void> Function()? onUseManagedDownload;

  @override
  Widget build(BuildContext context) {
    final helpText = _buildSupportHint(
      failureKind: failureKind,
      rawMessage: message,
      source: source,
    );

    return _SetupPanel(
      statusColor: Theme.of(context).colorScheme.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _StageLabel(
            icon: Icons.error_outline,
            label: 'Model setup failed',
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (helpText != null) ...<Widget>[
            const SizedBox(height: 12),
            _DiagnosticBlock(text: helpText),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  AppHaptics.trigger(AppHapticPattern.action);
                  onRetry();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry setup'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  AppHaptics.trigger(AppHapticPattern.action);
                  onImportLocalModel();
                },
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import local model'),
              ),
              if (onUseManagedDownload != null)
                TextButton.icon(
                  onPressed: () {
                    AppHaptics.trigger(AppHapticPattern.selection);
                    onUseManagedDownload!();
                  },
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Use managed download'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _buildSupportHint({
    required GemmaStartupFailureKind? failureKind,
    required String rawMessage,
    required ModelSourceConfig? source,
  }) {
    switch (failureKind) {
      case GemmaStartupFailureKind.modelSource:
        return 'Run with --dart-define=GHOSTEYE_GEMMA_MODEL_URL=https://your-host/model.task '
            'or import a local model file from this screen before the first run continues.';
      case GemmaStartupFailureKind.missingToken:
        if (source?.isHuggingFace ?? false) {
          return 'The configured Hugging Face source requires authentication. '
              'Provide GHOSTEYE_GEMMA_TOKEN or switch to a managed download/local import.';
        }
        return 'The configured managed download requires credentials. '
            'Provide GHOSTEYE_GEMMA_TOKEN if your service expects a bearer token, '
            'or update the managed model URL.';
      case GemmaStartupFailureKind.modelAccess:
        if (source?.isHuggingFace ?? false) {
          return 'Check that the Hugging Face repository URL and token are both valid, '
              'or switch to your managed download/local import flow.';
        }
        return 'Check that the managed model URL is correct and that any credentials are still valid.';
      case GemmaStartupFailureKind.network:
        if (source?.isFile ?? false) {
          return 'Import another supported model file, or switch back to managed download.';
        }
        return 'Check that the device has internet access for the initial model download, '
            'then retry on Wi-Fi if possible.';
      case GemmaStartupFailureKind.backendInitialization:
        return 'Try the first run on a physical iPhone. The simulator is not a reliable target '
            'for this on-device Gemma runtime.';
      case GemmaStartupFailureKind.modelLoad:
        return 'If the download completed, retry once. If it keeps failing, remove the cached model '
            'and let Ghosteye download it again.';
      case GemmaStartupFailureKind.localModel:
        return source?.isImportedFile ?? false
            ? 'The imported file is missing or unreadable. Import another supported model file, '
                'or switch back to managed download.'
            : 'The configured local model path could not be opened. Check '
                '--dart-define=GHOSTEYE_GEMMA_MODEL_PATH=/absolute/path/to/model.task '
                'or import another model file.';
      case GemmaStartupFailureKind.unknown:
      case null:
        break;
    }

    final normalizedMessage = rawMessage.toLowerCase();

    if (normalizedMessage.contains('401') ||
        normalizedMessage.contains('403') ||
        normalizedMessage.contains('huggingface') ||
        normalizedMessage.contains('access') ||
        normalizedMessage.contains('token')) {
      if (source?.isHuggingFace ?? false) {
        return 'The active model source appears to be on Hugging Face. '
            'Provide GHOSTEYE_GEMMA_TOKEN or switch to your managed download/local import flow.';
      }
      return 'Check the configured model source and any required credentials, '
          'or import a local model file instead.';
    }

    if (normalizedMessage.contains('network') ||
        normalizedMessage.contains('socket') ||
        normalizedMessage.contains('timeout')) {
      if (source?.isFile ?? false) {
        return 'Import another supported model file, or switch back to managed download.';
      }
      return 'Check that the device has internet access for the initial model download, '
          'then retry on Wi-Fi if possible.';
    }

    return null;
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({required this.source});

  final ModelSourceConfig? source;

  @override
  Widget build(BuildContext context) {
    final title = source?.label ?? 'Choose a model source';
    final detail = switch (source?.kind) {
      ModelSourceKind.network =>
        'Managed download is the recommended path for regular users.',
      ModelSourceKind.file when source?.isImportedFile ?? false =>
        'This local model has been copied into app storage and will be reused.',
      ModelSourceKind.file =>
        'Ghosteye will prepare the configured file path without a network download.',
      null => 'Add a managed URL in config.json or import a local model file.',
    };
    final metadata = source == null
        ? 'No active source'
        : '${source!.kind.name.toUpperCase()} - ${source!.modelId}';

    return _SectionBlock(
      title: 'Active source',
      child: _InfoRow(
        icon: source?.kind == ModelSourceKind.file
            ? Icons.sd_storage_outlined
            : Icons.cloud_download_outlined,
        title: title,
        detail: detail,
        trailing: metadata,
      ),
    );
  }
}

class _PreflightChecklist extends StatelessWidget {
  const _PreflightChecklist({required this.source});

  final ModelSourceConfig? source;

  @override
  Widget build(BuildContext context) {
    final networkDetail = source?.kind == ModelSourceKind.file
        ? 'Local source selected. Network is only needed if you switch back to managed download.'
        : 'Use Wi-Fi for the first model download. Camera frames still stay on-device.';

    return _SectionBlock(
      title: 'Before camera opens',
      child: Column(
        children: <Widget>[
          _PreflightRow(
            icon: Icons.wifi_tethering_outlined,
            label: 'Network',
            detail: networkDetail,
          ),
          const _Divider(),
          const _PreflightRow(
            icon: Icons.inventory_2_outlined,
            label: 'Storage',
            detail:
                'Keep room for a large on-device model file and future saved takes.',
          ),
          const _Divider(),
          const _PreflightRow(
            icon: Icons.battery_charging_full_outlined,
            label: 'Power',
            detail:
                'First install and first inference can run warm. Start with enough battery for setup.',
          ),
          const _Divider(),
          const _PreflightRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy',
            detail:
                'The network is for model delivery only. Scene frames and generated takes stay local.',
          ),
          const _Divider(),
          const _PreflightRow(
            icon: Icons.phone_iphone_outlined,
            label: 'Device',
            detail:
                'Use Android hardware or a physical iPhone for reliable runtime validation.',
          ),
        ],
      ),
    );
  }
}

class _SetupFallbackActions extends StatelessWidget {
  const _SetupFallbackActions({
    required this.isBusy,
    required this.usesImportedModel,
    required this.onImportLocalModel,
    required this.onUseManagedDownload,
  });

  final bool isBusy;
  final bool usesImportedModel;
  final Future<void> Function() onImportLocalModel;
  final Future<void> Function() onUseManagedDownload;

  @override
  Widget build(BuildContext context) {
    return _SectionBlock(
      title: 'Source controls',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () {
                    AppHaptics.trigger(AppHapticPattern.action);
                    onImportLocalModel();
                  },
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import local model'),
          ),
          if (usesImportedModel)
            TextButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      AppHaptics.trigger(AppHapticPattern.selection);
                      onUseManagedDownload();
                    },
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Use managed download'),
            ),
        ],
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({
    required this.statusColor,
    required this.child,
  });

  final Color statusColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC11151C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: const SizedBox(width: 4),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary.withOpacity(0.88),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(detail, style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              Text(
                trailing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreflightRow extends StatelessWidget {
  const _PreflightRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticBlock extends StatelessWidget {
  const _DiagnosticBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline, size: 18, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.white10),
    );
  }
}
