import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/providers/script_export_provider.dart';
import 'package:ghosteye/services/script_export_service.dart';
import 'package:ghosteye/widgets/script_export_sheet.dart';

class _RecordingExportService extends ScriptExportService {
  ScriptExportFormat? sharedFormat;
  ScriptExportFormat? copiedFormat;
  String? sharedNotes;
  String? copiedNotes;

  @override
  Future<void> shareDocument({
    required ScriptExportFormat format,
    required List<ScriptEntry> entries,
    required String title,
    DateTime? capturedAt,
    String notes = '',
  }) async {
    sharedFormat = format;
    sharedNotes = notes;
  }

  @override
  Future<void> copyDocument({
    required ScriptExportFormat format,
    required List<ScriptEntry> entries,
    required String title,
    DateTime? capturedAt,
    String notes = '',
  }) async {
    copiedFormat = format;
    copiedNotes = notes;
  }
}

const _entries = <ScriptEntry>[
  ScriptEntry(type: ScriptEntryType.slugline, text: 'INT. ROOM - NIGHT'),
];

Future<void> _openSheet(
  WidgetTester tester,
  _RecordingExportService service, {
  List<ScriptEntry> entries = _entries,
  String notes = '',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        scriptExportServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => ScriptExportSheet(
                  title: 'Take',
                  entries: entries,
                  notes: notes,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('share delegates the chosen format and notes to the service',
      (tester) async {
    final service = _RecordingExportService();
    await _openSheet(tester, service, notes: 'Push in on the door');

    await tester.tap(find.text('Share Fountain'));
    await tester.pumpAndSettle();

    expect(service.sharedFormat, ScriptExportFormat.fountain);
    expect(service.sharedNotes, 'Push in on the door');
  });

  testWidgets('copy delegates the chosen format and notes to the service',
      (tester) async {
    final service = _RecordingExportService();
    await _openSheet(tester, service, notes: 'Reshoot wider');

    await tester.tap(find.text('Copy Plain Text'));
    await tester.pumpAndSettle();

    expect(service.copiedFormat, ScriptExportFormat.plainText);
    expect(service.copiedNotes, 'Reshoot wider');
  });

  testWidgets('export actions are disabled when there are no entries',
      (tester) async {
    final service = _RecordingExportService();
    await _openSheet(tester, service, entries: const <ScriptEntry>[]);

    // FilledButton.icon builds a private FilledButton subclass, so match by
    // `is` rather than exact type.
    final shareFinder = find.ancestor(
      of: find.text('Share Fountain'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(shareFinder, findsOneWidget);
    expect(tester.widget<FilledButton>(shareFinder).onPressed, isNull);
  });
}
