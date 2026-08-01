import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/widgets/director_tips_sheet.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String primaryLabel,
  required VoidCallback onPrimaryPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorTipsSheet(
          primaryLabel: primaryLabel,
          onPrimaryPressed: onPrimaryPressed,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the tips content and the provided primary label',
      (tester) async {
    await _pump(
      tester,
      primaryLabel: 'Start shooting',
      onPrimaryPressed: () {},
    );

    expect(find.text('Before the first take'), findsOneWidget);
    expect(find.text('Set the shot'), findsOneWidget);
    expect(find.text('Switch the tone'), findsOneWidget);
    expect(find.text('Keep the good takes'), findsOneWidget);
    expect(find.text('Start shooting'), findsOneWidget);
  });

  testWidgets('primary button invokes the callback', (tester) async {
    var pressed = false;
    await _pump(
      tester,
      primaryLabel: 'Back to scene',
      onPrimaryPressed: () => pressed = true,
    );

    await tester.tap(find.text('Back to scene'));
    await tester.pump();

    expect(pressed, isTrue);
  });
}
