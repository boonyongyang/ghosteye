import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/constants.dart';
import 'package:ghosteye/services/camera_service.dart';

void main() {
  test('FrameSampler throttles frames while inference is running', () {
    var now = DateTime(2026, 1, 1, 12, 0, 0);
    final sampler = FrameSampler(
      interval: const Duration(milliseconds: 1500),
      now: () => now,
    );

    expect(sampler.shouldSample(), isTrue);
    expect(sampler.shouldSample(), isFalse);

    sampler.markInferenceComplete();
    now = now.add(const Duration(milliseconds: 1499));
    expect(sampler.shouldSample(), isFalse);

    now = now.add(const Duration(milliseconds: 1));
    expect(sampler.shouldSample(), isTrue);
  });

  test('CameraService increases interval when inference is slow', () {
    final service = CameraService();

    final nextInterval = service.computeAdaptiveInterval(
      previous: AppConstants.frameSampleInterval,
      inferenceDuration: const Duration(seconds: 5),
    );

    expect(nextInterval, greaterThan(AppConstants.frameSampleInterval));
  });

  test('computeAdaptiveInterval resets to baseInterval on fast inference', () {
    final service = CameraService();
    const fastBase = Duration(milliseconds: 800);

    final result = service.computeAdaptiveInterval(
      previous: const Duration(milliseconds: 3000),
      inferenceDuration: const Duration(milliseconds: 1200),
      baseInterval: fastBase,
    );

    expect(result, fastBase);
  });

  test('computeAdaptiveInterval floors slow result at baseInterval', () {
    final service = CameraService();
    const cinematicBase = Duration(milliseconds: 2500);

    final result = service.computeAdaptiveInterval(
      previous: cinematicBase,
      inferenceDuration: const Duration(seconds: 4),
      baseInterval: cinematicBase,
    );

    expect(result.inMilliseconds,
        greaterThanOrEqualTo(cinematicBase.inMilliseconds));
  });

  test('computeAdaptiveInterval default baseInterval is frameSampleInterval',
      () {
    final service = CameraService();

    final withDefault = service.computeAdaptiveInterval(
      previous: AppConstants.frameSampleInterval,
      inferenceDuration: const Duration(milliseconds: 500),
    );

    expect(withDefault, AppConstants.frameSampleInterval);
  });

  test('classifyCameraFailure detects permanently denied permissions', () {
    final failure = classifyCameraFailure(
      CameraException(
        'CameraAccessDeniedWithoutPrompt',
        'Permission was denied earlier.',
      ),
    );

    expect(failure.kind, CameraFailureKind.permissionDeniedPermanently);
    expect(failure.canOpenSettings, isTrue);
  });
}
