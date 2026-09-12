import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/theme.dart';
import 'package:ghosteye/models/model_source.dart';
import 'package:ghosteye/models/onboarding_status.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';
import 'package:ghosteye/screens/onboarding_screen.dart';
import 'package:ghosteye/screens/splash_screen.dart';
import 'package:ghosteye/services/gemma_service.dart';

/// iPhone SE / small Android class. The smallest viewport the app realistically
/// has to survive, and the one where a fixed-height panel or an un-scrollable
/// column shows up as an overflow stripe.
const Size _compact = Size(320, 568);

class _FixedGemma extends GemmaNotifier {
  _FixedGemma(this.initialState);

  final GemmaState initialState;

  @override
  Future<GemmaState> build() async => initialState;

  @override
  Future<void> ensureReady() async {
    state = AsyncData(initialState);
  }

  @override
  Future<void> importLocalModel() async {}

  @override
  Future<void> useManagedDownload() async {}

  @override
  Future<void> resetCachedInstall() async {}

  @override
  Future<void> resetConversation() async {}

  @override
  Future<void> cancelGeneration() async {}
}

class _FreshOnboarding extends OnboardingController {
  @override
  Future<OnboardingStatus> build() async => const OnboardingStatus.initial();

  @override
  Future<void> completeIntro() async {}

  @override
  Future<void> markDirectorTipsSeen() async {}
}

const _managedSource = ModelSourceConfig(
  kind: ModelSourceKind.network,
  origin: ModelSourceOrigin.envUrl,
  location: 'https://cdn.example.com/models/gemma-4-E2B-it.litertlm',
  label: 'Managed download',
);

Future<void> _pumpCompact(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = _compact;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.darkTheme, home: home),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump();
}

/// A RenderFlex overflow is reported as a framework exception, so an empty
/// exception queue is the assertion.
void _expectNoOverflow(WidgetTester tester, String label) {
  expect(
    tester.takeException(),
    isNull,
    reason: '$label overflows at ${_compact.width}x${_compact.height}',
  );
}

void main() {
  testWidgets('onboarding lays out on a compact viewport', (tester) async {
    await _pumpCompact(
      tester,
      const OnboardingScreen(),
      overrides: <Override>[
        onboardingProvider.overrideWith(_FreshOnboarding.new),
      ],
    );

    _expectNoOverflow(tester, 'onboarding intro');
  });

  testWidgets('onboarding handoff page lays out on a compact viewport', (
    tester,
  ) async {
    await _pumpCompact(
      tester,
      const OnboardingScreen(),
      overrides: <Override>[
        onboardingProvider.overrideWith(_FreshOnboarding.new),
      ],
    );

    // The densest page: it adds the two model-source cards.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
    }

    expect(find.text('Choose the model path'), findsOneWidget);
    _expectNoOverflow(tester, 'onboarding handoff');
  });

  testWidgets('setup progress lays out on a compact viewport', (tester) async {
    await _pumpCompact(
      tester,
      const SplashScreen(),
      overrides: <Override>[
        gemmaProvider.overrideWith(
          () => _FixedGemma(
            const GemmaState(
              phase: GemmaPhase.downloading,
              progress: 62,
              message: 'Downloading the on-device model',
              source: _managedSource,
            ),
          ),
        ),
      ],
    );

    _expectNoOverflow(tester, 'setup progress');
  });

  testWidgets('setup failure lays out on a compact viewport', (tester) async {
    await _pumpCompact(
      tester,
      const SplashScreen(),
      overrides: <Override>[
        gemmaProvider.overrideWith(
          () => _FixedGemma(
            const GemmaState(
              phase: GemmaPhase.error,
              message: 'The model download could not be reached.',
              source: _managedSource,
              failureKind: GemmaStartupFailureKind.network,
              diagnosticDetail: 'SocketException: Failed host lookup',
            ),
          ),
        ),
      ],
    );

    _expectNoOverflow(tester, 'setup failure');
  });
}
