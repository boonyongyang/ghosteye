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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF050608),
              Color(0xFF121722),
              Color(0xFF080A0F),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _BrandMark(),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appTitle,
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'First run prepares the on-device model before Ghosteye opens the camera.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                gemmaState.when(
                  data: (state) => state.hasError
                      ? _SplashError(
                          message: state.message ?? 'Unable to load model',
                          failureKind: state.failureKind,
                          source: state.source,
                          onRetry: _retrySetup,
                          onImportLocalModel: _importLocalModel,
                          onUseManagedDownload: state.usesImportedModel
                              ? _useManagedDownload
                              : null,
                        )
                      : _SplashProgress(state: state),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => _SplashError(
                    message: error.toString(),
                    onRetry: _retrySetup,
                    onImportLocalModel: _importLocalModel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const BrandMark();
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress({required this.state});

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
      GemmaPhase.idle => 'Preparing',
    };

    final sourceDetail = switch (state.source?.kind) {
      ModelSourceKind.file when state.source?.isImportedFile ?? false =>
        'Source: imported local model. Ghosteye will reuse this copied file on later launches before opening the director view.',
      ModelSourceKind.file =>
        'Source: configured local model path. Ghosteye will prepare it locally before opening the camera.',
      ModelSourceKind.network when state.source?.isLegacyHuggingFace ?? false =>
        'Source: legacy Hugging Face fallback. First launch downloads a large on-device model, so Wi-Fi is recommended before camera access starts.',
      ModelSourceKind.network =>
        'Source: managed download. First launch downloads a large on-device model, so Wi-Fi is recommended before camera access starts.',
      null =>
        'First launch downloads a large on-device model, so Wi-Fi is recommended before camera access starts.',
    };

    final detail = switch (state.phase) {
      GemmaPhase.ready when state.usedFallback =>
        'GPU setup failed, so Ghosteye switched to CPU. It should still work, but inference may feel slower.',
      GemmaPhase.ready when state.activeBackend != null =>
        '${AppConstants.modelDisplayName} is ready on ${state.activeBackend!.name.toUpperCase()} via ${state.source?.label.toLowerCase() ?? 'the active source'}.',
      _ => sourceDetail,
    };

    return Column(
      children: <Widget>[
        LinearProgressIndicator(value: progressValue),
        const SizedBox(height: 16),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({
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

    return Column(
      children: <Widget>[
        Text(
          'Model setup failed',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (helpText != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            helpText,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            AppHaptics.trigger(AppHapticPattern.action);
            onRetry();
          },
          child: const Text('Retry'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            AppHaptics.trigger(AppHapticPattern.action);
            onImportLocalModel();
          },
          child: const Text('Import local model'),
        ),
        if (onUseManagedDownload != null) ...<Widget>[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              AppHaptics.trigger(AppHapticPattern.selection);
              onUseManagedDownload!();
            },
            child: const Text('Use managed download'),
          ),
        ],
      ],
    );
  }

  String? _buildSupportHint({
    required GemmaStartupFailureKind? failureKind,
    required String rawMessage,
    required ModelSourceConfig? source,
  }) {
    switch (failureKind) {
      case GemmaStartupFailureKind.missingToken:
        if (source?.isLegacyHuggingFace ?? false) {
          return 'This build is still using the legacy Hugging Face fallback. '
              'Run with --dart-define=GHOSTEYE_GEMMA_TOKEN=hf_xxx, set '
              '--dart-define=GHOSTEYE_GEMMA_MODEL_URL=https://your-host/model.task, '
              'or import a local model file.';
        }
        if (source?.isHuggingFace ?? false) {
          return 'The active Hugging Face source requires authentication. '
              'Provide GHOSTEYE_GEMMA_TOKEN or switch to a managed download/local import.';
        }
        return 'The configured managed download requires credentials. '
            'Provide GHOSTEYE_GEMMA_TOKEN if your service expects a bearer token, '
            'or update the managed model URL.';
      case GemmaStartupFailureKind.modelAccess:
        if (source?.isHuggingFace ?? false) {
          return 'Make sure the token can access ${AppConstants.legacyModelRepository}, '
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

    final message = rawMessage.toLowerCase();

    if (message.contains('401') ||
        message.contains('403') ||
        message.contains('huggingface') ||
        message.contains('access') ||
        message.contains('token')) {
      if (source?.isHuggingFace ?? false) {
        return 'The active model source appears to be on Hugging Face. '
            'Provide GHOSTEYE_GEMMA_TOKEN or switch to your managed download/local import flow.';
      }
      return 'Check the configured model source and any required credentials, '
          'or import a local model file instead.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      if (source?.isFile ?? false) {
        return 'Import another supported model file, or switch back to managed download.';
      }
      return 'Check that the device has internet access for the initial model download, '
          'then retry on Wi-Fi if possible.';
    }

    return null;
  }
}
