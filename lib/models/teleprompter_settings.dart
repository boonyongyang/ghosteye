import 'package:flutter/foundation.dart';

enum TeleprompterTextSize {
  compact('COMPACT', 0.9),
  standard('STANDARD', 1.0),
  large('LARGE', 1.25);

  const TeleprompterTextSize(this.label, this.scale);

  final String label;
  final double scale;
}

enum TeleprompterDensity {
  tight('TIGHT', 4),
  cozy('COZY', 10),
  roomy('ROOMY', 18);

  const TeleprompterDensity(this.label, this.lineGap);

  final String label;
  final double lineGap;
}

enum TeleprompterPace {
  calm('CALM', Duration(milliseconds: 55)),
  natural('NATURAL', Duration(milliseconds: 35)),
  brisk('BRISK', Duration(milliseconds: 16));

  const TeleprompterPace(this.label, this.charDelay);

  final String label;
  final Duration charDelay;
}

@immutable
class TeleprompterSettings {
  const TeleprompterSettings({
    this.textSize = TeleprompterTextSize.standard,
    this.density = TeleprompterDensity.cozy,
    this.pace = TeleprompterPace.natural,
  });

  final TeleprompterTextSize textSize;
  final TeleprompterDensity density;
  final TeleprompterPace pace;

  TeleprompterSettings copyWith({
    TeleprompterTextSize? textSize,
    TeleprompterDensity? density,
    TeleprompterPace? pace,
  }) {
    return TeleprompterSettings(
      textSize: textSize ?? this.textSize,
      density: density ?? this.density,
      pace: pace ?? this.pace,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeleprompterSettings &&
        other.textSize == textSize &&
        other.density == density &&
        other.pace == pace;
  }

  @override
  int get hashCode => Object.hash(textSize, density, pace);
}
