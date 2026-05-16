enum PerformancePreset {
  cinematic('CINEMATIC', Duration(milliseconds: 2500),
      'Slow, deliberate framing — best battery life.'),
  balanced('BALANCED', Duration(milliseconds: 1500),
      'Default cadence — reliable on most devices.'),
  fast('FAST', Duration(milliseconds: 800),
      'Aggressive sampling — hottest on-device load.');

  const PerformancePreset(this.displayName, this.baseInterval, this.description);

  final String displayName;
  final Duration baseInterval;
  final String description;
}
