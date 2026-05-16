import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/model_source.dart';
import '../models/performance_preset.dart';
import '../providers/camera_provider.dart';
import '../providers/gemma_provider.dart';
import '../providers/session_controls_provider.dart';
import '../services/app_haptics.dart';
import '../services/gemma_service.dart';

class ModelCenterSheet extends ConsumerWidget {
  const ModelCenterSheet({
    super.key,
    required this.onResetCachedInstall,
  });

  final VoidCallback onResetCachedInstall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gemmaAsync = ref.watch(gemmaProvider);
    final gemmaState = gemmaAsync.valueOrNull;
    final preset = ref.watch(performancePresetProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF11151C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Model Center',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'MODEL'),
              const SizedBox(height: 8),
              _ModelRow(source: gemmaState?.source),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'RUNTIME'),
              const SizedBox(height: 8),
              _RuntimeRow(
                backend: gemmaState?.activeBackend,
                usedFallback: gemmaState?.usedFallback ?? false,
              ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'SPEED'),
              const SizedBox(height: 8),
              _PresetPicker(
                selected: preset,
                onSelect: (next) {
                  AppHaptics.trigger(AppHapticPattern.selection);
                  ref.read(performancePresetProvider.notifier).state = next;
                  ref.read(cameraProvider.notifier).applyPreset(next);
                },
              ),
              const SizedBox(height: 4),
              Text(
                preset.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'PRIVACY'),
              const SizedBox(height: 8),
              _PrivacyRow(),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              _ResetButton(onReset: onResetCachedInstall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white38,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.source});
  final ModelSourceConfig? source;

  @override
  Widget build(BuildContext context) {
    if (source == null) {
      return Text(
        'No model configured',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.white54),
      );
    }

    final kindLabel = source!.isNetwork ? 'MANAGED' : 'LOCAL';
    const kindColor = Color(0xFF67D7EE);

    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kindColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kindColor.withOpacity(0.35)),
          ),
          child: Text(
            kindLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kindColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            source!.label,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RuntimeRow extends StatelessWidget {
  const _RuntimeRow({required this.backend, required this.usedFallback});
  final RuntimeBackend? backend;
  final bool usedFallback;

  @override
  Widget build(BuildContext context) {
    final backendLabel = switch (backend) {
      RuntimeBackend.gpu => 'GPU',
      RuntimeBackend.cpu => 'CPU',
      null => 'Unknown',
    };

    final color = (backend == RuntimeBackend.cpu || usedFallback)
        ? const Color(0xFFFFA726)
        : Colors.white70;

    return Row(
      children: <Widget>[
        Icon(
          backend == RuntimeBackend.gpu
              ? Icons.memory_outlined
              : Icons.developer_board_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          backendLabel,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
        if (usedFallback) ...<Widget>[
          const SizedBox(width: 6),
          Text(
            '(CPU fallback)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFFA726),
                ),
          ),
        ],
      ],
    );
  }
}

class _PresetPicker extends StatelessWidget {
  const _PresetPicker({required this.selected, required this.onSelect});
  final PerformancePreset selected;
  final ValueChanged<PerformancePreset> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PerformancePreset.values.map((preset) {
        final isActive = preset == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(preset),
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
                    preset.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive ? Colors.white : Colors.white38,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.lock_outline, size: 14, color: Colors.white38),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Camera frames never leave this device. '
            'Network is used only to download the model.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
        ),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.refresh_outlined, size: 16),
        label: const Text('Reset cached install'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
