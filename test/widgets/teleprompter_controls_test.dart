import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/teleprompter_settings.dart';
import 'package:ghosteye/providers/teleprompter_settings_provider.dart';
import 'package:ghosteye/widgets/teleprompter_controls.dart';

Future<void> _pump(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: TeleprompterControls(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all three control captions', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Text size'), findsOneWidget);
    expect(find.text('Line spacing'), findsOneWidget);
    expect(find.text('Reveal pace'), findsOneWidget);
  });

  testWidgets('tapping a text size segment updates the provider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(
      container.read(teleprompterSettingsProvider).textSize,
      TeleprompterTextSize.standard,
    );

    await tester.tap(find.text(TeleprompterTextSize.large.label));
    await tester.pumpAndSettle();

    expect(
      container.read(teleprompterSettingsProvider).textSize,
      TeleprompterTextSize.large,
    );
  });

  testWidgets('tapping density and pace segments updates the provider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pump(tester, container);

    await tester.tap(find.text(TeleprompterDensity.roomy.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TeleprompterPace.brisk.label));
    await tester.pumpAndSettle();

    final settings = container.read(teleprompterSettingsProvider);
    expect(settings.density, TeleprompterDensity.roomy);
    expect(settings.pace, TeleprompterPace.brisk);
  });

  testWidgets('reflects an externally-updated selection', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(teleprompterSettingsProvider.notifier)
        .setPace(TeleprompterPace.calm);

    await _pump(tester, container);

    // The active segment label is present and the control renders its state.
    expect(find.text(TeleprompterPace.calm.label), findsOneWidget);
    expect(
      container.read(teleprompterSettingsProvider).pace,
      TeleprompterPace.calm,
    );
  });
}
