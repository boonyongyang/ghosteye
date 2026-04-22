import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_status.dart';
import 'model_source_service.dart';
import 'script_history_service.dart';

typedef LoadOnboardingPreferencesFn = Future<SharedPreferences> Function();

class OnboardingService {
  OnboardingService({
    LoadOnboardingPreferencesFn? loadPreferences,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const onboardingIntroCompleteKey =
      'ghosteye.onboarding_intro_complete';
  static const directorTipsSeenKey = 'ghosteye.director_tips_seen';

  final LoadOnboardingPreferencesFn _loadPreferences;

  Future<OnboardingStatus> loadStatus() async {
    final preferences = await _loadPreferences();
    await _seedLegacyInstallStatus(preferences);

    return OnboardingStatus(
      introComplete: preferences.getBool(onboardingIntroCompleteKey) ?? false,
      directorTipsSeen: preferences.getBool(directorTipsSeenKey) ?? false,
    );
  }

  Future<void> markIntroComplete() async {
    final preferences = await _loadPreferences();
    await preferences.setBool(onboardingIntroCompleteKey, true);
  }

  Future<void> markDirectorTipsSeen() async {
    final preferences = await _loadPreferences();
    await preferences.setBool(directorTipsSeenKey, true);
  }

  Future<void> _seedLegacyInstallStatus(SharedPreferences preferences) async {
    final hasIntroFlag = preferences.containsKey(onboardingIntroCompleteKey);
    final hasDirectorTipsFlag = preferences.containsKey(directorTipsSeenKey);

    if (hasIntroFlag && hasDirectorTipsFlag) {
      return;
    }

    if (!_hasExistingUsage(preferences)) {
      return;
    }

    if (!hasIntroFlag) {
      await preferences.setBool(onboardingIntroCompleteKey, true);
    }
    if (!hasDirectorTipsFlag) {
      await preferences.setBool(directorTipsSeenKey, true);
    }
  }

  bool _hasExistingUsage(SharedPreferences preferences) {
    final installedSourceSignature =
        preferences.getString(ModelSourceService.installedSourceSignatureKey);
    final importedModelPath =
        preferences.getString(ModelSourceService.importedModelPathKey);
    final savedHistory =
        preferences.getStringList(ScriptHistoryService.historyStorageKey);

    return (installedSourceSignature?.isNotEmpty ?? false) ||
        (importedModelPath?.isNotEmpty ?? false) ||
        (savedHistory?.isNotEmpty ?? false);
  }
}
