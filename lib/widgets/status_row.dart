import 'package:flutter/material.dart';

class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.detail,
    this.trailing,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? detail;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? Colors.white70;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: resolvedIconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              if (detail != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(detail!, style: theme.textTheme.bodySmall),
              ],
              if (trailing != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  trailing!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
