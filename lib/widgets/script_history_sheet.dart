import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/script_session.dart';
import '../providers/script_history_provider.dart';
import '../services/app_haptics.dart';

class ScriptHistorySheet extends ConsumerWidget {
  const ScriptHistorySheet({
    super.key,
    required this.onSelectSession,
    required this.onExportSession,
  });

  final Future<void> Function(ScriptSession session) onSelectSession;
  final Future<void> Function(ScriptSession session) onExportSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(scriptHistoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF11151C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Recent takes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap a take to reopen it in the teleprompter. Ghosteye pauses live capture first.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  historyState.valueOrNull?.isNotEmpty == true
                      ? TextButton(
                          onPressed: () {
                            AppHaptics.trigger(AppHapticPattern.emphasis);
                            ref.read(scriptHistoryProvider.notifier).clearAll();
                          },
                          child: const Text('Clear all'),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: historyState.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return const _EmptyHistoryState(
                        message:
                            'Ghosteye will save recent screenplay takes here after the first completed scene.',
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _HistoryCard(
                          session: session,
                          onOpen: () => onSelectSession(session),
                          onExport: () => onExportSession(session),
                          onDelete: () {
                            ref
                                .read(scriptHistoryProvider.notifier)
                                .deleteSession(session.id);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => const _EmptyHistoryState(
                    message: 'Ghosteye could not load saved takes right now.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.session,
    required this.onOpen,
    required this.onExport,
    required this.onDelete,
  });

  final ScriptSession session;
  final Future<void> Function() onOpen;
  final Future<void> Function() onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = session.preview.isEmpty ? 'Untitled take' : session.preview;

    return Material(
      color: const Color(0xFF171C25),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppHaptics.trigger(AppHapticPattern.action);
          onOpen();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _formatTimestamp(session.updatedAt.toLocal()),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Export take',
                    onPressed: () {
                      AppHaptics.trigger(AppHapticPattern.selection);
                      onExport();
                    },
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete take',
                    onPressed: () {
                      AppHaptics.trigger(AppHapticPattern.emphasis);
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${session.lineCount} lines saved',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  final now = DateTime.now();
  final isSameDay = now.year == value.year &&
      now.month == value.month &&
      now.day == value.day;

  final hour = value.hour == 0
      ? 12
      : value.hour > 12
          ? value.hour - 12
          : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';

  if (isSameDay) {
    return 'Today $hour:$minute $meridiem';
  }

  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute $meridiem';
}
