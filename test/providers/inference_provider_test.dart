import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/onboarding_status.dart';
import 'package:ghosteye/providers/camera_provider.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/providers/inference_provider.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';
import 'package:ghosteye/services/camera_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notifiers that never resolve — valueOrNull stays null for the full test.
// Each extends the concrete notifier so overrideWith type-checks cleanly.

class _LoadingCameraNotifier extends CameraControllerNotifier {
  @override
  Future<CameraSession> build() => Completer<CameraSession>().future;
}

class _LoadingGemmaNotifier extends GemmaNotifier {
  @override
  Future<GemmaState> build() => Completer<GemmaState>().future;
}

class _LoadingOnboardingController extends OnboardingController {
  @override
  Future<OnboardingStatus> build() => Completer<OnboardingStatus>().future;
}

class _ReadyOnboardingController extends OnboardingController {
  final OnboardingStatus _status;
  _ReadyOnboardingController(this._status);

  @override
  Future<OnboardingStatus> build() async => _status;
}

/// Creates a container where camera and gemma are permanently loading (null).
/// Pass [onboardingFactory] to use a custom onboarding state instead.
ProviderContainer _containerWithLoadingDeps({
  OnboardingController Function()? onboardingFactory,
}) {
  return ProviderContainer(
    overrides: [
      cameraProvider.overrideWith(_LoadingCameraNotifier.new),
      gemmaProvider.overrideWith(_LoadingGemmaNotifier.new),
      onboardingProvider.overrideWith(
        onboardingFactory ?? _LoadingOnboardingController.new,
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('InferenceStatusState', () {
    test('default state is idle with no active generation', () {
      const state = InferenceStatusState();
      expect(state.activity, equals(InferenceActivity.idle));
      expect(state.activeGenerationId, isNull);
      expect(state.errorMessage, isNull);
      expect(state.lastInferenceDuration, isNull);
      expect(state.errorKind, isNull);
    });

    test('copyWith preserves existing values when nothing is overridden', () {
      const original = InferenceStatusState(
        activity: InferenceActivity.processing,
        lastInferenceDuration: Duration(milliseconds: 500),
        activeGenerationId: 42,
      );
      final copy = original.copyWith();

      expect(copy.activity, equals(InferenceActivity.processing));
      expect(
        copy.lastInferenceDuration,
        equals(const Duration(milliseconds: 500)),
      );
      expect(copy.activeGenerationId, equals(42));
    });

    test('copyWith overrides the specified activity field', () {
      const original = InferenceStatusState(
        activity: InferenceActivity.processing,
        activeGenerationId: 7,
      );
      final copy = original.copyWith(activity: InferenceActivity.idle);

      expect(copy.activity, equals(InferenceActivity.idle));
      expect(copy.activeGenerationId, equals(7));
    });

    test('copyWith always clears the nullable error fields', () {
      const original = InferenceStatusState(
        activity: InferenceActivity.error,
        errorMessage: 'timeout',
      );
      final copy = original.copyWith(activity: InferenceActivity.idle);

      expect(copy.errorMessage, isNull);
    });
  });

  group('InferenceEvent', () {
    test('processing event carries generationId and no token', () {
      const event = InferenceEvent.processing(5);

      expect(event.activity, equals(InferenceActivity.processing));
      expect(event.generationId, equals(5));
      expect(event.token, isNull);
      expect(event.errorMessage, isNull);
      expect(event.duration, isNull);
    });

    test('token event carries token text and generationId', () {
      const event = InferenceEvent.token('Hello', 3);

      expect(event.activity, equals(InferenceActivity.processing));
      expect(event.token, equals('Hello'));
      expect(event.generationId, equals(3));
    });

    test('completed event carries duration and generationId', () {
      const event = InferenceEvent.completed(Duration(milliseconds: 800), 2);

      expect(event.activity, equals(InferenceActivity.idle));
      expect(event.duration, equals(const Duration(milliseconds: 800)));
      expect(event.generationId, equals(2));
      expect(event.token, isNull);
    });

    test('error event carries message and generationId', () {
      const event = InferenceEvent.error('timeout', 9);

      expect(event.activity, equals(InferenceActivity.error));
      expect(event.errorMessage, equals('timeout'));
      expect(event.generationId, equals(9));
      expect(event.token, isNull);
    });
  });

  group('inferenceStatusProvider', () {
    test('starts in idle state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(inferenceStatusProvider).activity,
        equals(InferenceActivity.idle),
      );
    });
  });

  group('inferenceGenerationCounterProvider', () {
    test('starts at zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(inferenceGenerationCounterProvider), equals(0));
    });

    test('can be incremented', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(inferenceGenerationCounterProvider.notifier)
          .update((state) => state + 1);

      expect(container.read(inferenceGenerationCounterProvider), equals(1));
    });
  });

  group('inferenceProvider status side effects', () {
    test('resets inferenceStatus to idle when camera is not yet ready',
        () async {
      final container = _containerWithLoadingDeps();
      addTearDown(container.dispose);

      // Pre-set a non-idle status to verify the reset
      container.read(inferenceStatusProvider.notifier).state =
          const InferenceStatusState(activity: InferenceActivity.processing);

      // Listening triggers the StreamProvider body
      container.listen(inferenceProvider, (_, __) {});
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(inferenceStatusProvider).activity,
        equals(InferenceActivity.idle),
      );
    });

    test(
        'camera-unavailable path dominates even when onboarding has not been seen',
        () async {
      // Camera is still loading → the null-camera guard fires before
      // the onboarding check, so the result is still idle.
      final container = _containerWithLoadingDeps(
        onboardingFactory: () => _ReadyOnboardingController(
          const OnboardingStatus(introComplete: true, directorTipsSeen: false),
        ),
      );
      addTearDown(container.dispose);

      container.listen(inferenceProvider, (_, __) {});
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(inferenceStatusProvider).activity,
        equals(InferenceActivity.idle),
      );
    });
  });
}
