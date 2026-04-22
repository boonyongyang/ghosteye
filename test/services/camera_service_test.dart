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
