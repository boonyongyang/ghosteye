import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/teleprompter_settings.dart';
import '../providers/teleprompter_settings_provider.dart';
import '../services/app_haptics.dart';

/// Segmented pickers for teleprompter text size, line spacing, and reveal pace.
/// Reads and writes [teleprompterSettingsProvider]; safe to embed in any sheet.
class TeleprompterControls extends ConsumerWidget {
  const TeleprompterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(teleprompterSettingsProvider);
    final controller = ref.read(teleprompterSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SegmentRow<TeleprompterTextSize>(
          caption: 'Text size',
          values: TeleprompterTextSize.values,
          selected: settings.textSize,
          labelOf: (value) => value.label,
          onSelect: controller.setTextSize,
        ),
        const SizedBox(height: 14),
        _SegmentRow<TeleprompterDensity>(
          caption: 'Line spacing',
          values: TeleprompterDensity.values,
          selected: settings.density,
          labelOf: (value) => value.label,
          onSelect: controller.setDensity,
        ),
        const SizedBox(height: 14),
        _SegmentRow<TeleprompterPace>(
          caption: 'Reveal pace',
          values: TeleprompterPace.values,
          selected: settings.pace,
          labelOf: (value) => value.label,
          onSelect: controller.setPace,
        ),
      ],
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.caption,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final String caption;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          caption,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: values.map((value) {
            final isActive = value == selected;
            final isLast = value == values.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: GestureDetector(
                  onTap: () {
                    if (isActive) {
                      return;
                    }
                    AppHaptics.trigger(AppHapticPattern.selection);
                    onSelect(value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? Colors.white38 : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labelOf(value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive ? Colors.white : Colors.white38,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}
