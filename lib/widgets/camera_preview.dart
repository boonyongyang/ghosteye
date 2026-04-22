import 'package:camera/camera.dart' as camera_plugin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../providers/camera_provider.dart';
import '../services/app_haptics.dart';
import '../services/camera_service.dart';

class DirectorCameraPreview extends StatelessWidget {
  const DirectorCameraPreview({
    super.key,
    required this.cameraState,
  });

  final AsyncValue<CameraSession> cameraState;

  @override
  Widget build(BuildContext context) {
    return cameraState.when(
      data: (session) {
        final controller = session.controller;
        if (!controller.value.isInitialized) {
          return const _PreviewFallback(message: 'Initializing camera');
        }

        return ColoredBox(
          color: Colors.black,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize?.height ?? 1080,
              height: controller.value.previewSize?.width ?? 1920,
              child: camera_plugin.CameraPreview(controller),
            ),
          ),
        );
      },
      loading: () => const _PreviewFallback(message: 'Starting camera'),
      error: (error, stackTrace) =>
          _PreviewFallback(failure: classifyCameraFailure(error)),
    );
  }
}

class _PreviewFallback extends ConsumerWidget {
  const _PreviewFallback({
    this.message,
    this.failure,
  });

  final String? message;
  final CameraFailure? failure;

  Future<void> _openSettings(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppConstants.settingsUri),
      mode: LaunchMode.externalApplication,
    );

    if (opened || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open Settings. Please open it manually.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = this.failure;
    final retryLabel = switch (failure?.kind) {
      CameraFailureKind.permissionDenied => 'Grant Access',
      _ => 'Retry Camera',
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF080B11),
            Color(0xFF161D28),
            Color(0xFF090B10),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.videocam_off_outlined,
                  color: Colors.white70, size: 42),
              const SizedBox(height: 12),
              Text(
                failure?.title ?? 'Camera not ready',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                failure?.guidance ??
                    message ??
                    'Ghosteye could not start the camera yet.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  if (failure?.canOpenSettings ?? false)
                    FilledButton.tonal(
                      onPressed: () {
                        AppHaptics.trigger(AppHapticPattern.action);
                        _openSettings(context);
                      },
                      child: const Text('Open Settings'),
                    ),
                  if (failure?.canRetry ?? true)
                    OutlinedButton(
                      onPressed: () {
                        AppHaptics.trigger(AppHapticPattern.action);
                        ref.read(cameraProvider.notifier).refresh();
                      },
                      child: Text(retryLabel),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
