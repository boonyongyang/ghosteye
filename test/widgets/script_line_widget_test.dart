import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/widgets/script_line_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Finder _inScriptLine(Finder matcher) => find.descendant(
      of: find.byType(ScriptLineWidget),
      matching: matcher,
    );

void main() {
  group('ScriptLineWidget', () {
    testWidgets('slugline renders text uppercased', (tester) async {
      const entry = ScriptEntry(
        type: ScriptEntryType.slugline,
        text: 'Int. office - day',
      );
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(find.text('INT. OFFICE - DAY'), findsOneWidget);
    });

    testWidgets('action renders text as-is without modification',
        (tester) async {
      const entry = ScriptEntry(
        type: ScriptEntryType.action,
        text: 'Rain needles the window.',
      );
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(find.text('Rain needles the window.'), findsOneWidget);
    });

    testWidgets('character renders text uppercased', (tester) async {
      const entry = ScriptEntry(type: ScriptEntryType.character, text: 'mara');
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(find.text('MARA'), findsOneWidget);
    });

    testWidgets('character renders inside a centred Align', (tester) async {
      const entry =
          ScriptEntry(type: ScriptEntryType.character, text: 'JONES');
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      final align = tester.widget<Align>(
        _inScriptLine(find.byType(Align)),
      );
      expect(align.alignment, equals(Alignment.center));
    });

    testWidgets('dialogue renders text as-is', (tester) async {
      const entry = ScriptEntry(
        type: ScriptEntryType.dialogue,
        text: 'This city never sleeps.',
      );
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(find.text('This city never sleeps.'), findsOneWidget);
    });

    testWidgets('dialogue text has centre alignment', (tester) async {
      const entry = ScriptEntry(
        type: ScriptEntryType.dialogue,
        text: 'Hello.',
      );
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      final text = tester.widget<Text>(find.text('Hello.'));
      expect(text.textAlign, equals(TextAlign.center));
    });

    testWidgets('dialogue renders inside horizontal padding', (tester) async {
      const entry = ScriptEntry(type: ScriptEntryType.dialogue, text: 'Hello.');
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(_inScriptLine(find.byType(Padding)), findsWidgets);
    });

    testWidgets('parenthetical renders text as-is', (tester) async {
      const entry =
          ScriptEntry(type: ScriptEntryType.parenthetical, text: '(beat)');
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(find.text('(beat)'), findsOneWidget);
    });

    testWidgets('parenthetical text has centre alignment', (tester) async {
      const entry = ScriptEntry(
        type: ScriptEntryType.parenthetical,
        text: '(softly)',
      );
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      final text = tester.widget<Text>(find.text('(softly)'));
      expect(text.textAlign, equals(TextAlign.center));
    });

    testWidgets('parenthetical renders inside horizontal padding',
        (tester) async {
      const entry = ScriptEntry(
        type: ScriptEntryType.parenthetical,
        text: '(quietly)',
      );
      await tester.pumpWidget(_wrap(const ScriptLineWidget(entry: entry)));

      expect(_inScriptLine(find.byType(Padding)), findsWidgets);
    });

    testWidgets('every ScriptEntryType renders without throwing',
        (tester) async {
      for (final type in ScriptEntryType.values) {
        final entry = ScriptEntry(type: type, text: 'Sample text');
        await tester.pumpWidget(_wrap(ScriptLineWidget(entry: entry)));
        expect(tester.takeException(), isNull,
            reason: 'threw for type $type');
      }
    });
  });
}
