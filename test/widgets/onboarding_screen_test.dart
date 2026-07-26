import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/onboarding_status.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';
import 'package:ghosteye/screens/onboarding_screen.dart';
import 'package:go_router/go_router.dart';

/// Records `completeIntro` calls and can hold the call open so tests can
/// observe the screen's in-flight submitting state.
class _RecordingOnboardingController extends OnboardingController {
  _RecordingOnboardingController({this.gate});

  /// When supplied, `completeIntro` waits on this before resolving.
  final Future<void>? gate;

  int completeIntroCalls = 0;

  @override
  Future<OnboardingStatus> build() async => const OnboardingStatus.initial();

  @override
  Future<void> completeIntro() async {
    completeIntroCalls += 1;
    if (gate != null) {
      await gate;
    }
    state = const AsyncData(
      OnboardingStatus(introComplete: true, directorTipsSeen: false),
    );
  }

  @override
  Future<void> markDirectorTipsSeen() async {}
}

const _setupMarker = 'SETUP ROUTE';

Future<_RecordingOnboardingController> _pumpOnboarding(
  WidgetTester tester, {
  Future<void>? gate,
}) async {
  final controller = _RecordingOnboardingController(gate: gate);

  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const Scaffold(body: Text(_setupMarker)),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        onboardingProvider.overrideWith(() => controller),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return controller;
}

/// Taps the primary bottom action ("Next" / "Start setup") by label.
Future<void> _tapPrimary(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the first page with no Back affordance',
      (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text('Keep the shot on the device'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    // Back is intentionally absent on the first page.
    expect(find.widgetWithText(OutlinedButton, 'Back'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
  });

  testWidgets('Back appears after advancing and returns to the prior page',
      (tester) async {
    await _pumpOnboarding(tester);

    await _tapPrimary(tester, 'Next');
    expect(find.text('Prep the model before the camera rolls'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);

    final backButton = find.widgetWithText(OutlinedButton, 'Back');
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Keep the shot on the device'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Back'), findsNothing);
  });

  testWidgets('the last page swaps the primary action to Start setup',
      (tester) async {
    await _pumpOnboarding(tester);

    await _tapPrimary(tester, 'Next');
    await _tapPrimary(tester, 'Next');
    expect(find.text('03'), findsOneWidget);

    await _tapPrimary(tester, 'Next');

    expect(find.text('Choose the model path'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Next'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Start setup'), findsOneWidget);
  });

  testWidgets('Skip completes onboarding once and routes to setup',
      (tester) async {
    final controller = await _pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(controller.completeIntroCalls, 1);
    expect(find.text(_setupMarker), findsOneWidget);
  });

  testWidgets('an in-flight submit disables the actions and blocks re-entry',
      (tester) async {
    final gate = Completer<void>();
    final controller = await _pumpOnboarding(tester, gate: gate.future);

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(controller.completeIntroCalls, 1);

    // While the submit is in flight both actions are disabled...
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Skip')).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next')).onPressed,
      isNull,
    );

    // ...so a second tap cannot double-complete onboarding.
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(controller.completeIntroCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(_setupMarker), findsOneWidget);
  });
}
