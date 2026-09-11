import 'package:flutter/material.dart';

import '../models/script_entry.dart';

class ScriptLineWidget extends StatelessWidget {
  const ScriptLineWidget({
    super.key,
    required this.entry,
    this.textScale = 1.0,
  });

  final ScriptEntry entry;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (entry.type) {
      ScriptEntryType.slugline => Text(
        entry.text.toUpperCase(),
        style: _scaled(
          theme.textTheme.titleMedium,
        )?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
      ),
      ScriptEntryType.action => Text(
        entry.text,
        style: _scaled(theme.textTheme.bodyLarge),
      ),
      ScriptEntryType.character => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            entry.text.toUpperCase(),
            style: _scaled(
              theme.textTheme.bodyMedium,
            )?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      ScriptEntryType.dialogue => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            entry.text,
            textAlign: TextAlign.center,
            style: _scaled(theme.textTheme.bodyLarge),
          ),
        ),
      ),
      ScriptEntryType.parenthetical => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            entry.text,
            textAlign: TextAlign.center,
            style: _scaled(
              theme.textTheme.bodyMedium,
            )?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
        ),
      ),
    };
  }

  TextStyle? _scaled(TextStyle? style) {
    return style?.copyWith(fontSize: (style.fontSize ?? 14) * textScale);
  }
}
