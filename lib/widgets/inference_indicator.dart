import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../providers/inference_provider.dart';

class InferenceIndicator extends StatefulWidget {
  const InferenceIndicator({
    super.key,
    required this.status,
    required this.captureEnabled,
    this.isDegraded = false,
  });

  final InferenceStatusState status;
  final bool captureEnabled;
  final bool isDegraded;

  @override
  State<InferenceIndicator> createState() => _InferenceIndicatorState();
}

class _InferenceIndicatorState extends State<InferenceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant InferenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status.activity == InferenceActivity.processing &&
        widget.captureEnabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.captureEnabled
        ? widget.status.activity
        : InferenceActivity.paused;
    final showDegraded =
        widget.isDegraded && activity != InferenceActivity.error;

    final color = switch (activity) {
      _ when showDegraded => const Color(0xFFF2B95C),
      InferenceActivity.idle => AppTheme.success,
      InferenceActivity.paused => Colors.white70,
      InferenceActivity.processing => Theme.of(context).colorScheme.primary,
      InferenceActivity.error => AppTheme.error,
    };

    final label = showDegraded
        ? switch (activity) {
            InferenceActivity.idle => 'CPU READY',
            InferenceActivity.paused => 'CPU PAUSED',
            InferenceActivity.processing => 'CPU THINKING',
            InferenceActivity.error => 'ERROR',
          }
        : switch (activity) {
            InferenceActivity.idle => 'IDLE',
            InferenceActivity.paused => 'PAUSED',
            InferenceActivity.processing => 'THINKING',
            InferenceActivity.error => 'ERROR',
          };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ScaleTransition(
          scale: Tween<double>(begin: 0.78, end: 1.05).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const SizedBox.square(dimension: 12),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(letterSpacing: 1.2),
        ),
      ],
    );
  }
}
