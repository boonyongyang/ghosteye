import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/routes.dart';
import 'package:ghosteye/models/onboarding_status.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';

class _FakeOnboardingController extends OnboardingController {
  _FakeOnboardingController(this.initialState);

  final OnboardingStatus initialState;

  @override
  Future<OnboardingStatus> build() async => initialState;

  @override
  Future<void> completeIntro() async {
    state = AsyncData(initialState.copyWith(introComplete: true));
  }

  @override
  Future<void> markDirectorTipsSeen() async {
    state = AsyncData(initialState.copyWith(directorTipsSeen: true));
  }
}

class _FakeGemmaNotifier extends GemmaNotifier {
  _FakeGemmaNotifier(this.initialState);

  final GemmaState initialState;

  @override
  Future<GemmaState> build() async => initialState;

  @override
  Future<void> ensureReady() async {
    state = AsyncData(initialState);
  }

  @override
  Future<void> resetConversation() async {}

  @override
  Future<void> cancelGeneration() async {}
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required OnboardingStatus onboardingStatus,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        onboardingProvider.overrideWith(
          () => _FakeOnboardingController(onboardingStatus),
        ),
        gemmaProvider.overrideWith(
          () => _FakeGemmaNotifier(
            const GemmaState(
              phase: GemmaPhase.downloading,
              progress: 12,
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: createAppRouter(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('fresh installs route to onboarding first', (tester) async {
    await _pumpApp(
      tester,
      onboardingStatus: const OnboardingStatus.initial(),
    );

    expect(find.text('Keep the shot on the device'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('start setup advances from onboarding to setup', (tester) async {
    await _pumpApp(
      tester,
      onboardingStatus: const OnboardingStatus.initial(),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Let the model prep before the camera rolls'),
        findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
        find.text('Direct the tone, then keep the good takes'), findsOneWidget);

    await tester.tap(find.text('Start setup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(
      find.text(
        'First run prepares the on-device model before Ghosteye opens the camera.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('skip also advances from onboarding to setup', (tester) async {
    await _pumpApp(
      tester,
      onboardingStatus: const OnboardingStatus.initial(),
    );

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(
      find.text(
        'First run prepares the on-device model before Ghosteye opens the camera.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('returning users bypass onboarding and land on setup',
      (tester) async {
    await _pumpApp(
      tester,
      onboardingStatus: const OnboardingStatus(
        introComplete: true,
        directorTipsSeen: true,
      ),
    );

    expect(find.text('Start setup'), findsNothing);
    expect(
      find.text(
        'First run prepares the on-device model before Ghosteye opens the camera.',
      ),
      findsOneWidget,
    );
  });
}
