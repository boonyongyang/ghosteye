class OnboardingStatus {
  const OnboardingStatus({
    required this.introComplete,
    required this.directorTipsSeen,
  });

  const OnboardingStatus.initial()
      : introComplete = false,
        directorTipsSeen = false;

  final bool introComplete;
  final bool directorTipsSeen;

  OnboardingStatus copyWith({
    bool? introComplete,
    bool? directorTipsSeen,
  }) {
    return OnboardingStatus(
      introComplete: introComplete ?? this.introComplete,
      directorTipsSeen: directorTipsSeen ?? this.directorTipsSeen,
    );
  }
}
