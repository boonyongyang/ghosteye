import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/script_entry.dart';
import '../providers/script_export_provider.dart';
import '../services/app_haptics.dart';
import '../services/script_export_service.dart';

class ScriptExportSheet extends ConsumerWidget {
  const ScriptExportSheet({
    super.key,
    required this.title,
    required this.entries,
    this.capturedAt,
    this.notes = '',
  });

  final String title;
  final List<ScriptEntry> entries;
  final DateTime? capturedAt;
  final String notes;

  bool get hasEntries => entries.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF11151C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
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
                    'Export take',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasEntries
                        ? 'Share or copy this take as Fountain or plain text.'
                        : 'Complete or reopen a take first, then export it from here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  _ExportActionRow(
                    label: 'Fountain',
                    shareLabel: 'Share Fountain',
                    copyLabel: 'Copy Fountain',
                    enabled: hasEntries,
                    onShare: () => _shareDocument(
                      context,
                      ref,
                      format: ScriptExportFormat.fountain,
                    ),
                    onCopy: () => _copyDocument(
                      context,
                      ref,
                      format: ScriptExportFormat.fountain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ExportActionRow(
                    label: 'Plain text',
                    shareLabel: 'Share Plain Text',
                    copyLabel: 'Copy Plain Text',
                    enabled: hasEntries,
                    onShare: () => _shareDocument(
                      context,
                      ref,
                      format: ScriptExportFormat.plainText,
                    ),
                    onCopy: () => _copyDocument(
                      context,
                      ref,
                      format: ScriptExportFormat.plainText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareDocument(
    BuildContext context,
    WidgetRef ref, {
    required ScriptExportFormat format,
  }) async {
    AppHaptics.trigger(AppHapticPattern.selection);
    await ref.read(scriptExportServiceProvider).shareDocument(
          format: format,
          entries: entries,
          title: title,
          capturedAt: capturedAt,
          notes: notes,
        );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _copyDocument(
    BuildContext context,
    WidgetRef ref, {
    required ScriptExportFormat format,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    AppHaptics.trigger(AppHapticPattern.action);
    await ref.read(scriptExportServiceProvider).copyDocument(
          format: format,
          entries: entries,
          title: title,
          capturedAt: capturedAt,
          notes: notes,
        );
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          switch (format) {
            ScriptExportFormat.fountain =>
              'Copied Fountain export to the clipboard.',
            ScriptExportFormat.plainText =>
              'Copied plain-text export to the clipboard.',
          },
        ),
      ),
    );
  }
}

class _ExportActionRow extends StatelessWidget {
  const _ExportActionRow({
    required this.label,
    required this.shareLabel,
    required this.copyLabel,
    required this.enabled,
    required this.onShare,
    required this.onCopy,
  });

  final String label;
  final String shareLabel;
  final String copyLabel;
  final bool enabled;
  final Future<void> Function() onShare;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final compactWidth = MediaQuery.sizeOf(context).width < 420;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF171C25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            compactWidth
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: enabled ? onShare : null,
                        icon: const Icon(Icons.ios_share_outlined),
                        label: Text(shareLabel),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: enabled ? onCopy : null,
                        icon: const Icon(Icons.copy_all_outlined),
                        label: Text(copyLabel),
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: enabled ? onShare : null,
                          icon: const Icon(Icons.ios_share_outlined),
                          label: Text(shareLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: enabled ? onCopy : null,
                          icon: const Icon(Icons.copy_all_outlined),
                          label: Text(copyLabel),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
