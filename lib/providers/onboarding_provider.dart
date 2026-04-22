import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_status.dart';
import '../services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final onboardingProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingStatus>(
  OnboardingController.new,
);

class OnboardingController extends AsyncNotifier<OnboardingStatus> {
  @override
  Future<OnboardingStatus> build() async {
    return ref.read(onboardingServiceProvider).loadStatus();
  }

  Future<void> completeIntro() async {
    final service = ref.read(onboardingServiceProvider);
    await service.markIntroComplete();
    final current = state.valueOrNull ?? await service.loadStatus();
    state = AsyncData(current.copyWith(introComplete: true));
  }

  Future<void> markDirectorTipsSeen() async {
    final service = ref.read(onboardingServiceProvider);
    await service.markDirectorTipsSeen();
    final current = state.valueOrNull ?? await service.loadStatus();
    state = AsyncData(current.copyWith(directorTipsSeen: true));
  }
}
