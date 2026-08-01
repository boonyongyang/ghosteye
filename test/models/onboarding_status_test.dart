import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/onboarding_status.dart';

void main() {
  group('OnboardingStatus', () {
    test('initial() has both flags false', () {
      const status = OnboardingStatus.initial();
      expect(status.introComplete, isFalse);
      expect(status.directorTipsSeen, isFalse);
    });

    test('copyWith updates only the provided flag', () {
      const status = OnboardingStatus.initial();

      final introDone = status.copyWith(introComplete: true);
      expect(introDone.introComplete, isTrue);
      expect(introDone.directorTipsSeen, isFalse);

      final tipsDone = introDone.copyWith(directorTipsSeen: true);
      expect(tipsDone.introComplete, isTrue);
      expect(tipsDone.directorTipsSeen, isTrue);
    });

    test('copyWith with no arguments preserves both flags', () {
      const status = OnboardingStatus(
        introComplete: true,
        directorTipsSeen: false,
      );
      final copy = status.copyWith();
      expect(copy.introComplete, isTrue);
      expect(copy.directorTipsSeen, isFalse);
    });
  });
}
