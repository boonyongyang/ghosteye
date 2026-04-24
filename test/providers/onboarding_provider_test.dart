import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';
import 'package:ghosteye/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<OnboardingService> _makeService({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  return OnboardingService(loadPreferences: () async => preferences);
}

ProviderContainer _makeContainer(OnboardingService service) {
  return ProviderContainer(
    overrides: [onboardingServiceProvider.overrideWithValue(service)],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads false flags for fresh install', () async {
    final service = await _makeService();
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    final status = await container.read(onboardingProvider.future);

    expect(status.introComplete, isFalse);
    expect(status.directorTipsSeen, isFalse);
  });

  test('loads true flags when prefs already set', () async {
    final service = await _makeService(prefs: {
      OnboardingService.onboardingIntroCompleteKey: true,
      OnboardingService.directorTipsSeenKey: true,
    });
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    final status = await container.read(onboardingProvider.future);

    expect(status.introComplete, isTrue);
    expect(status.directorTipsSeen, isTrue);
  });

  test('completeIntro sets introComplete to true in state and persists it',
      () async {
    final service = await _makeService();
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    await container.read(onboardingProvider.future);
    await container.read(onboardingProvider.notifier).completeIntro();

    final status = container.read(onboardingProvider).valueOrNull;
    expect(status, isNotNull);
    expect(status!.introComplete, isTrue);
    expect(status.directorTipsSeen, isFalse);

    // Verify it also wrote to the underlying service
    final reloaded = await service.loadStatus();
    expect(reloaded.introComplete, isTrue);
  });

  test('markDirectorTipsSeen sets directorTipsSeen in state and persists it',
      () async {
    final service = await _makeService();
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    await container.read(onboardingProvider.future);
    await container.read(onboardingProvider.notifier).markDirectorTipsSeen();

    final status = container.read(onboardingProvider).valueOrNull;
    expect(status, isNotNull);
    expect(status!.directorTipsSeen, isTrue);
    expect(status.introComplete, isFalse);

    final reloaded = await service.loadStatus();
    expect(reloaded.directorTipsSeen, isTrue);
  });

  test('both flags can be set independently without affecting each other',
      () async {
    final service = await _makeService();
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    await container.read(onboardingProvider.future);
    await container.read(onboardingProvider.notifier).completeIntro();
    await container.read(onboardingProvider.notifier).markDirectorTipsSeen();

    final status = container.read(onboardingProvider).valueOrNull;
    expect(status!.introComplete, isTrue);
    expect(status.directorTipsSeen, isTrue);
  });

  test('completeIntro does not change directorTipsSeen when it was already true',
      () async {
    final service = await _makeService(prefs: {
      OnboardingService.directorTipsSeenKey: true,
    });
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    await container.read(onboardingProvider.future);
    await container.read(onboardingProvider.notifier).completeIntro();

    final status = container.read(onboardingProvider).valueOrNull;
    expect(status!.introComplete, isTrue);
    expect(status.directorTipsSeen, isTrue);
  });
}
