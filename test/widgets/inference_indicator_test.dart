import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/providers/inference_provider.dart';
import 'package:ghosteye/widgets/inference_indicator.dart';

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required InferenceActivity activity,
  required bool captureEnabled,
  bool isDegraded = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InferenceIndicator(
          status: InferenceStatusState(activity: activity),
          captureEnabled: captureEnabled,
          isDegraded: isDegraded,
        ),
      ),
    ),
  );
  // Note: the pulse animation repeats forever, so callers use pump(), never
  // pumpAndSettle().
}

void main() {
  testWidgets('shows IDLE / THINKING / ERROR for the active status',
      (tester) async {
    await _pumpIndicator(
      tester,
      activity: InferenceActivity.idle,
      captureEnabled: true,
    );
    expect(find.text('IDLE'), findsOneWidget);

    await _pumpIndicator(
      tester,
      activity: InferenceActivity.processing,
      captureEnabled: true,
    );
    expect(find.text('THINKING'), findsOneWidget);

    await _pumpIndicator(
      tester,
      activity: InferenceActivity.error,
      captureEnabled: true,
    );
    expect(find.text('ERROR'), findsOneWidget);
  });

  testWidgets('capture disabled overrides the status to PAUSED',
      (tester) async {
    await _pumpIndicator(
      tester,
      activity: InferenceActivity.processing,
      captureEnabled: false,
    );

    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('THINKING'), findsNothing);
  });

  testWidgets('degraded runtime prefixes non-error states with CPU',
      (tester) async {
    await _pumpIndicator(
      tester,
      activity: InferenceActivity.idle,
      captureEnabled: true,
      isDegraded: true,
    );
    expect(find.text('CPU READY'), findsOneWidget);

    await _pumpIndicator(
      tester,
      activity: InferenceActivity.processing,
      captureEnabled: true,
      isDegraded: true,
    );
    expect(find.text('CPU THINKING'), findsOneWidget);
  });

  testWidgets('error state is not decorated as a CPU-degraded state',
      (tester) async {
    await _pumpIndicator(
      tester,
      activity: InferenceActivity.error,
      captureEnabled: true,
      isDegraded: true,
    );

    expect(find.text('ERROR'), findsOneWidget);
    expect(find.text('CPU THINKING'), findsNothing);
  });
}
