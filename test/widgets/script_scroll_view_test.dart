import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/models/script_session.dart';
import 'package:ghosteye/providers/script_provider.dart';
import 'package:ghosteye/providers/session_controls_provider.dart';
import 'package:ghosteye/widgets/script_scroll_view.dart';

Future<void> _pump(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: ScriptScrollView()),
      ),
    ),
  );
}

ScriptSession _session(List<ScriptEntry> entries) => ScriptSession(
      id: 's1',
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
      entries: entries,
    );

void main() {
  testWidgets('shows the live prompt when capture is enabled and empty',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(
      find.text('Scene is live — screenplay will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the paused prompt when capture is disabled and empty',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(captureEnabledProvider.notifier).state = false;

    await _pump(tester, container);

    expect(find.text('Capture paused.'), findsOneWidget);
  });

  testWidgets('renders loaded screenplay entries', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(scriptProvider.notifier).loadSessionForReview(
          _session(const <ScriptEntry>[
            ScriptEntry(type: ScriptEntryType.slugline, text: 'INT. ROOM - NIGHT'),
            ScriptEntry(type: ScriptEntryType.action, text: 'Rain taps the glass.'),
          ]),
        );

    await _pump(tester, container);

    expect(find.text('INT. ROOM - NIGHT'), findsOneWidget);
    expect(find.text('Rain taps the glass.'), findsOneWidget);
    expect(
      find.text('Scene is live — screenplay will appear here.'),
      findsNothing,
    );
  });
}
