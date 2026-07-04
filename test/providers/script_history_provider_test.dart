import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/providers/script_history_provider.dart';
import 'package:ghosteye/services/thumbnail_encoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts encode calls and returns a distinct value each time so tests can
/// tell a reused thumbnail apart from a freshly re-encoded one.
class _CountingEncoder implements ThumbnailEncoder {
  int calls = 0;

  @override
  int get maxDimension => 160;

  @override
  int get quality => 55;

  @override
  String? encodeFromJpeg(Uint8List jpegBytes) {
    calls += 1;
    return 'thumb-$calls';
  }
}

const _entries = <ScriptEntry>[
  ScriptEntry(type: ScriptEntryType.action, text: 'A shot in the dark.'),
];

final _source = Uint8List.fromList(<int>[1, 2, 3, 4]);

Future<ProviderContainer> _readyContainer(ThumbnailEncoder encoder) async {
  final container = ProviderContainer(
    overrides: <Override>[
      thumbnailEncoderProvider.overrideWithValue(encoder),
    ],
  );
  addTearDown(container.dispose);
  await container.read(scriptHistoryProvider.future);
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('attaches an encoded thumbnail when a source frame is provided',
      () async {
    final container = await _readyContainer(_CountingEncoder());

    await container.read(scriptHistoryProvider.notifier).syncSession(
          sessionId: 's1',
          createdAt: DateTime.utc(2026, 5, 1),
          entries: _entries,
          thumbnailSource: _source,
        );

    final sessions = container.read(scriptHistoryProvider).valueOrNull!;
    expect(sessions.single.thumbnail, equals('thumb-1'));
  });

  test('leaves the thumbnail null when no source frame is provided', () async {
    final container = await _readyContainer(_CountingEncoder());

    await container.read(scriptHistoryProvider.notifier).syncSession(
          sessionId: 's1',
          createdAt: DateTime.utc(2026, 5, 1),
          entries: _entries,
        );

    expect(
      container.read(scriptHistoryProvider).valueOrNull!.single.thumbnail,
      isNull,
    );
  });

  test('reuses the first thumbnail on later syncs of the same take', () async {
    final encoder = _CountingEncoder();
    final container = await _readyContainer(encoder);
    final notifier = container.read(scriptHistoryProvider.notifier);

    await notifier.syncSession(
      sessionId: 's1',
      createdAt: DateTime.utc(2026, 5, 1),
      entries: _entries,
      thumbnailSource: _source,
    );
    await notifier.syncSession(
      sessionId: 's1',
      createdAt: DateTime.utc(2026, 5, 1),
      entries: _entries,
      thumbnailSource: _source,
    );

    final sessions = container.read(scriptHistoryProvider).valueOrNull!;
    expect(sessions.single.thumbnail, equals('thumb-1'));
    expect(encoder.calls, equals(1));
  });

  test('preserves an existing thumbnail through a favorite toggle', () async {
    final container = await _readyContainer(_CountingEncoder());
    final notifier = container.read(scriptHistoryProvider.notifier);

    await notifier.syncSession(
      sessionId: 's1',
      createdAt: DateTime.utc(2026, 5, 1),
      entries: _entries,
      thumbnailSource: _source,
    );
    await notifier.toggleFavorite('s1');

    final session = container.read(scriptHistoryProvider).valueOrNull!.single;
    expect(session.isFavorite, isTrue);
    expect(session.thumbnail, equals('thumb-1'));
  });
}
