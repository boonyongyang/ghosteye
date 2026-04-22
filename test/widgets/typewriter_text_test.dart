import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/widgets/typewriter_text.dart';

void main() {
  testWidgets('TypewriterText reveals characters over time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TypewriterText(
            targetText: 'CUT',
            charDelay: Duration(milliseconds: 10),
            cursorBlinkInterval: Duration(milliseconds: 20),
          ),
        ),
      ),
    );

    RichText richText() => tester.widget<RichText>(find.byType(RichText));

    expect(richText().text.toPlainText(), '|');

    await tester.pump(const Duration(milliseconds: 10));
    expect(richText().text.toPlainText(), 'C|');

    await tester.pump(const Duration(milliseconds: 10));
    expect(richText().text.toPlainText(), 'CU|');

    await tester.pump(const Duration(milliseconds: 10));
    expect(richText().text.toPlainText(), 'CUT|');
  });
}
