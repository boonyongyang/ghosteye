import 'package:flutter/material.dart';

import '../services/app_haptics.dart';

class DirectorTipsSheet extends StatelessWidget {
  const DirectorTipsSheet({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
  });

  final String primaryLabel;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF11151C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
              const SizedBox(height: 18),
              Text(
                'Before the first take',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Ghosteye is ready. Keep the phone steady, frame the shot you want, and let the first scene build intentionally.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              const _TipsCard(
                icon: Icons.videocam_outlined,
                title: 'Set the shot',
                body:
                    'Point Ghosteye at the moment you want to direct. Camera permission and model prep happen first, but every frame stays on-device.',
              ),
              const SizedBox(height: 12),
              const _TipsCard(
                icon: Icons.auto_stories_outlined,
                title: 'Switch the tone',
                body:
                    'NOIR leans shadowy, SCI-FI heightens detail, and SITCOM stays lighter. Change modes any time to redirect the writing voice.',
              ),
              const SizedBox(height: 12),
              const _TipsCard(
                icon: Icons.history_toggle_off_outlined,
                title: 'Keep the good takes',
                body:
                    'Recent finished scenes land in History, so you can pause, review, and reopen them without losing the live moment.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    AppHaptics.trigger(AppHapticPattern.action);
                    onPrimaryPressed();
                  },
                  child: Text(primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF171C25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x1AF2B95C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: const Color(0xFFF2B95C), size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
