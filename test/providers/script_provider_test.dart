import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/providers/script_history_provider.dart';
import 'package:ghosteye/providers/script_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('ScriptController parses Fountain-style responses into entries', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(scriptProvider.notifier);
    controller.startResponse(1);
    controller.appendToken(
      generationId: 1,
      token: 'INT. APARTMENT - NIGHT\n',
    );
    controller.appendToken(
      generationId: 1,
      token: 'Rain needles the window.\n',
    );
    controller.appendToken(
      generationId: 1,
      token: 'MARA\n',
    );
    controller.appendToken(
      generationId: 1,
      token: '(beat)\n',
    );
    controller.appendToken(
      generationId: 1,
      token: 'This city never sleeps.',
    );
    controller.finishResponse(1);

    final state = container.read(scriptProvider);

    expect(state.isGenerating, isFalse);
    expect(state.liveResponse, isEmpty);
    expect(state.entries.map((entry) => entry.type), <ScriptEntryType>[
      ScriptEntryType.slugline,
      ScriptEntryType.action,
      ScriptEntryType.character,
      ScriptEntryType.parenthetical,
      ScriptEntryType.dialogue,
    ]);
  });

  test('ScriptController ignores stale tokens after cancellation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(scriptProvider.notifier);
    controller.startResponse(3);
    controller.appendToken(
      generationId: 3,
      token: 'Rain over neon.\n',
    );
    controller.cancelActiveResponse();

    controller.appendToken(
      generationId: 3,
      token: 'This should never appear.',
    );
    controller.finishResponse(3);

    final state = container.read(scriptProvider);
    expect(state.liveResponse, isEmpty);
    expect(state.entries, isEmpty);
    expect(state.activeGenerationId, isNull);
  });

  test(
      'ScriptController clear resets visible script and later generations work',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(scriptProvider.notifier);
    controller.startResponse(1);
    controller.appendToken(
      generationId: 1,
      token: 'INT. GARAGE - NIGHT',
    );
    controller.finishResponse(1);

    controller.clear();

    controller.startResponse(2);
    controller.appendToken(
      generationId: 2,
      token: 'EXT. ROOFTOP - DAWN',
    );
    controller.finishResponse(2);

    final state = container.read(scriptProvider);
    expect(state.entries, hasLength(1));
    expect(state.entries.single.text, 'EXT. ROOFTOP - DAWN');
    expect(state.activeGenerationId, isNull);
  });

  test('ScriptController syncs completed takes into saved history', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(scriptProvider.notifier);
    controller.startResponse(1);
    controller.appendToken(
      generationId: 1,
      token: 'INT. APARTMENT - NIGHT\nRain needles the window.',
    );
    controller.finishResponse(1);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final sessions = await container.read(scriptHistoryProvider.future);

    expect(sessions, hasLength(1));
    expect(sessions.single.entries.first.text, 'INT. APARTMENT - NIGHT');
  });
}
