import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/teleprompter_settings.dart';
import 'package:ghosteye/providers/teleprompter_settings_provider.dart';
import 'package:ghosteye/widgets/teleprompter_controls.dart';

void main() {
  testWidgets('teleprompter controls expose and update all display settings', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: TeleprompterControls()),
        ),
      ),
    );

    expect(find.text('Text size'), findsOneWidget);
    expect(find.text('Line spacing'), findsOneWidget);
    expect(find.text('Reveal pace'), findsOneWidget);

    await tester.tap(find.text('LARGE'));
    await tester.pump();

    expect(
      container.read(teleprompterSettingsProvider).textSize,
      TeleprompterTextSize.large,
    );
  });
}
