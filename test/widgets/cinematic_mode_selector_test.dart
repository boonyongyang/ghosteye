import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/cinematic_mode.dart';
import 'package:ghosteye/providers/cinematic_mode_provider.dart';
import 'package:ghosteye/widgets/cinematic_mode_selector.dart';

void main() {
  testWidgets('CinematicModeSelector updates the selected mode',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: CinematicModeSelector(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SITCOM'));
    await tester.pumpAndSettle();

    expect(container.read(cinematicModeProvider), CinematicMode.sitcom);
  });

  testWidgets('CinematicModeSelector shows description for selected mode',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: CinematicModeSelector(),
          ),
        ),
      ),
    );

    expect(
      find.text(CinematicMode.noir.shortDescription),
      findsOneWidget,
    );

    await tester.tap(find.text('SCI-FI'));
    await tester.pumpAndSettle();

    expect(
      find.text(CinematicMode.sciFi.shortDescription),
      findsOneWidget,
    );
    expect(
      find.text(CinematicMode.noir.shortDescription),
      findsNothing,
    );
  });
}
