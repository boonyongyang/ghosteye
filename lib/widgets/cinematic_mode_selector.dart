import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cinematic_mode.dart';
import '../providers/cinematic_mode_provider.dart';
import '../services/app_haptics.dart';

class CinematicModeSelector extends ConsumerWidget {
  const CinematicModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(cinematicModeProvider);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: CinematicMode.values.map((mode) {
        final isSelected = mode == selectedMode;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            if (!isSelected) {
              AppHaptics.trigger(AppHapticPattern.selection);
            }
            ref.read(cinematicModeProvider.notifier).state = mode;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black54,
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white24,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.28),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              mode.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
