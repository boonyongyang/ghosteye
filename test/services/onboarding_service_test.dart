import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/services/model_source_service.dart';
import 'package:ghosteye/services/onboarding_service.dart';
import 'package:ghosteye/services/script_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<OnboardingService> _createService({
  required SharedPreferences preferences,
}) async {
  return OnboardingService(
    loadPreferences: () async => preferences,
  );
}

void main() {
  test('loadStatus seeds onboarding flags for legacy installs', () async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{
        ModelSourceService.installedSourceSignatureKey: 'envUrl:https://cdn',
      },
    );
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    final status = await service.loadStatus();

    expect(status.introComplete, isTrue);
    expect(status.directorTipsSeen, isTrue);
    expect(
      preferences.getBool(OnboardingService.onboardingIntroCompleteKey),
      isTrue,
    );
    expect(
      preferences.getBool(OnboardingService.directorTipsSeenKey),
      isTrue,
    );
  });

  test('loadStatus does not auto-complete fresh installs', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    final status = await service.loadStatus();

    expect(status.introComplete, isFalse);
    expect(status.directorTipsSeen, isFalse);
  });

  test('history also counts as existing usage for upgrade bypass', () async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{
        ScriptHistoryService.historyStorageKey: <String>['{"id":"saved-1"}'],
      },
    );
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    final status = await service.loadStatus();

    expect(status.introComplete, isTrue);
    expect(status.directorTipsSeen, isTrue);
  });

  test('markIntroComplete and markDirectorTipsSeen persist flags', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final service = await _createService(preferences: preferences);

    await service.markIntroComplete();
    await service.markDirectorTipsSeen();

    expect(
      preferences.getBool(OnboardingService.onboardingIntroCompleteKey),
      isTrue,
    );
    expect(
      preferences.getBool(OnboardingService.directorTipsSeenKey),
      isTrue,
    );
  });
}
