import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cinematic_mode.dart';
import '../models/script_session.dart';
import '../providers/script_history_provider.dart';
import '../services/app_haptics.dart';

enum _LibraryFilter { all, favorites, noir, sciFi, sitcom }

extension on _LibraryFilter {
  String get label => switch (this) {
        _LibraryFilter.all => 'ALL',
        _LibraryFilter.favorites => '★',
        _LibraryFilter.noir => 'NOIR',
        _LibraryFilter.sciFi => 'SCI-FI',
        _LibraryFilter.sitcom => 'SITCOM',
      };

  bool matches(ScriptSession session) => switch (this) {
        _LibraryFilter.all => true,
        _LibraryFilter.favorites => session.isFavorite,
        _LibraryFilter.noir => session.mode == CinematicMode.noir,
        _LibraryFilter.sciFi => session.mode == CinematicMode.sciFi,
        _LibraryFilter.sitcom => session.mode == CinematicMode.sitcom,
      };
}

class ScriptHistorySheet extends ConsumerStatefulWidget {
  const ScriptHistorySheet({
    super.key,
    required this.onSelectSession,
    required this.onExportSession,
  });

  final Future<void> Function(ScriptSession session) onSelectSession;
  final Future<void> Function(ScriptSession session) onExportSession;

  @override
  ConsumerState<ScriptHistorySheet> createState() => _ScriptHistorySheetState();
}

class _ScriptHistorySheetState extends ConsumerState<ScriptHistorySheet> {
  _LibraryFilter _filter = _LibraryFilter.all;

  @override
  Widget build(BuildContext context) {
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
                          'Take Library',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a take to reopen it. Ghosteye pauses live capture first.',
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
              const SizedBox(height: 12),
              _FilterBar(
                selected: _filter,
                onSelect: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: historyState.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return const _EmptyLibraryState(
                        message:
                            'Ghosteye will save recent screenplay takes here after the first completed scene.',
                      );
                    }

                    final sorted = <ScriptSession>[
                      ...sessions.where((s) => s.isFavorite),
                      ...sessions.where((s) => !s.isFavorite),
                    ];
                    final visible =
                        sorted.where(_filter.matches).toList(growable: false);

                    if (visible.isEmpty) {
                      return _EmptyLibraryState(
                        message: _filter == _LibraryFilter.favorites
                            ? 'No favorited takes yet. Tap ★ on a take to pin it.'
                            : 'No takes recorded in ${_filter.label} mode.',
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final session = visible[index];
                        return _TakeCard(
                          session: session,
                          onOpen: () => widget.onSelectSession(session),
                          onExport: () => widget.onExportSession(session),
                          onToggleFavorite: () {
                            AppHaptics.trigger(AppHapticPattern.selection);
                            ref
                                .read(scriptHistoryProvider.notifier)
                                .toggleFavorite(session.id);
                          },
                          onDelete: () {
                            AppHaptics.trigger(AppHapticPattern.emphasis);
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
                  error: (_, __) => const _EmptyLibraryState(
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelect});

  final _LibraryFilter selected;
  final ValueChanged<_LibraryFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _LibraryFilter.values.map((filter) {
          final isActive = filter == selected;
          final isMode = filter == _LibraryFilter.noir ||
              filter == _LibraryFilter.sciFi ||
              filter == _LibraryFilter.sitcom;
          final modeColor = isMode
              ? _modeColor(filter)
              : filter == _LibraryFilter.favorites
                  ? const Color(0xFFFDD663)
                  : null;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                AppHaptics.trigger(AppHapticPattern.selection);
                onSelect(filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isActive
                      ? (modeColor ?? Colors.white).withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isActive
                        ? (modeColor ?? Colors.white).withOpacity(0.5)
                        : Colors.white12,
                  ),
                ),
                child: Text(
                  filter.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? (modeColor ?? Colors.white)
                            : Colors.white38,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Color _modeColor(_LibraryFilter filter) => switch (filter) {
        _LibraryFilter.noir => CinematicMode.noir.badgeColor,
        _LibraryFilter.sciFi => CinematicMode.sciFi.badgeColor,
        _LibraryFilter.sitcom => CinematicMode.sitcom.badgeColor,
        _ => Colors.white,
      };
}

class _TakeCard extends StatelessWidget {
  const _TakeCard({
    required this.session,
    required this.onOpen,
    required this.onExport,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final ScriptSession session;
  final Future<void> Function() onOpen;
  final Future<void> Function() onExport;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = session.mode;

    return Material(
      color: const Color(0xFF171C25),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          AppHaptics.trigger(AppHapticPattern.action);
          onOpen();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (session.hasThumbnail) ...<Widget>[
                _TakeThumbnail(base64Jpeg: session.thumbnail!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (mode != null) ...<Widget>[
                          _ModeBadge(mode: mode),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        _IconAction(
                          icon: session.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: session.isFavorite
                              ? const Color(0xFFFDD663)
                              : Colors.white38,
                          tooltip: session.isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          onTap: onToggleFavorite,
                        ),
                        _IconAction(
                          icon: Icons.ios_share_outlined,
                          tooltip: 'Export take',
                          onTap: () {
                            AppHaptics.trigger(AppHapticPattern.selection);
                            onExport();
                          },
                        ),
                        _IconAction(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete take',
                          onTap: onDelete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${_formatTimestamp(session.updatedAt.toLocal())} · ${session.lineCount} lines',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakeThumbnail extends StatelessWidget {
  const _TakeThumbnail({required this.base64Jpeg});

  final String base64Jpeg;

  static const double _width = 54;
  static const double _height = 72;

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(base64Jpeg);
    if (bytes == null) {
      return const SizedBox(width: _width, height: _height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        bytes,
        width: _width,
        height: _height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: _width,
          height: _height,
          color: Colors.white10,
          child: const Icon(
            Icons.movie_outlined,
            size: 18,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }

  static Uint8List? _decode(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final CinematicMode mode;

  @override
  Widget build(BuildContext context) {
    final color = mode.badgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        mode.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 20,
      onPressed: onTap,
      icon: Icon(icon, color: color),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.message});

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
