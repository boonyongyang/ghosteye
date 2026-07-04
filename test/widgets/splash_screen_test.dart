import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/model_source.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/screens/splash_screen.dart';
import 'package:ghosteye/services/gemma_service.dart';

class _FakeGemmaNotifier extends GemmaNotifier {
  _FakeGemmaNotifier(this.initialState);

  final GemmaState initialState;
  bool importLocalModelCalled = false;
  bool useManagedDownloadCalled = false;
  bool resetCachedInstallCalled = false;

  @override
  Future<GemmaState> build() async => initialState;

  @override
  Future<void> ensureReady() async {
    state = AsyncData(initialState);
  }

  @override
  Future<void> importLocalModel() async {
    importLocalModelCalled = true;
  }

  @override
  Future<void> useManagedDownload() async {
    useManagedDownloadCalled = true;
  }

  @override
  Future<void> resetCachedInstall() async {
    resetCachedInstallCalled = true;
  }

  @override
  Future<void> resetConversation() async {}

  @override
  Future<void> cancelGeneration() async {}
}

Future<void> _pumpSplashScreen(
  WidgetTester tester,
  _FakeGemmaNotifier notifier,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        gemmaProvider.overrideWith(() => notifier),
      ],
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('SplashScreen shows managed download progress copy',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.downloading,
        progress: 42,
        source: ModelSourceConfig(
          kind: ModelSourceKind.network,
          origin: ModelSourceOrigin.envUrl,
          location: 'https://cdn.example.com/gemma.task',
          label: 'Managed download',
        ),
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(
        find.textContaining('Downloading Gemma 3 Nano (42%)'), findsOneWidget);
    expect(find.textContaining('Source: managed download'), findsOneWidget);
    expect(find.text('Active source'), findsOneWidget);
    expect(find.text('Before camera opens'), findsOneWidget);
    expect(find.text('Source controls'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.textContaining('Hugging Face'), findsNothing);
  });

  testWidgets('SplashScreen shows ready summary before opening camera',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.ready,
        source: ModelSourceConfig(
          kind: ModelSourceKind.network,
          origin: ModelSourceOrigin.envUrl,
          location: 'https://cdn.example.com/gemma.litertlm',
          label: 'Managed download',
        ),
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(find.text('Model ready'), findsOneWidget);
    expect(find.text('Active configuration'), findsOneWidget);
    expect(find.text('Runtime: GPU'), findsOneWidget);
    expect(find.text('Open camera'), findsOneWidget);
  });

  testWidgets(
      'SplashScreen shows setup guidance when no model source is configured',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.error,
        message:
            'Ghosteye needs a managed model download URL or a local model file before setup can continue.',
        failureKind: GemmaStartupFailureKind.modelSource,
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(find.text('Model setup failed'), findsOneWidget);
    expect(find.text('Show details'), findsOneWidget);
    expect(
      find.textContaining('--dart-define=GHOSTEYE_GEMMA_MODEL_URL'),
      findsNothing,
    );

    await tester.tap(find.text('Show details'));
    await tester.pump();

    expect(
      find.textContaining('--dart-define=GHOSTEYE_GEMMA_MODEL_URL'),
      findsOneWidget,
    );
    expect(find.textContaining('Hugging Face'), findsNothing);
    expect(find.text('Import local model'), findsOneWidget);
    expect(find.text('Source controls'), findsNothing);
  });

  testWidgets('SplashScreen shows managed-download token guidance',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.error,
        message: 'Missing token',
        failureKind: GemmaStartupFailureKind.missingToken,
        source: ModelSourceConfig(
          kind: ModelSourceKind.network,
          origin: ModelSourceOrigin.envUrl,
          location: 'https://cdn.example.com/gemma.task',
          label: 'Managed download',
        ),
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(find.text('Show details'), findsOneWidget);
    expect(find.textContaining('GHOSTEYE_GEMMA_TOKEN'), findsNothing);

    await tester.tap(find.text('Show details'));
    await tester.pump();

    expect(find.textContaining('GHOSTEYE_GEMMA_TOKEN'), findsOneWidget);
    expect(find.textContaining('Hugging Face'), findsNothing);
  });

  testWidgets('SplashScreen exposes copyable technical diagnostics on expand',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.error,
        message: 'Model could not be opened',
        failureKind: GemmaStartupFailureKind.modelLoad,
        diagnosticDetail: 'Exception: SOI marker missing at frobnicate()',
        source: ModelSourceConfig(
          kind: ModelSourceKind.network,
          origin: ModelSourceOrigin.envUrl,
          location: 'https://cdn.example.com/gemma.task',
          label: 'Managed download',
        ),
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    // Technical details stay hidden until the section is expanded.
    expect(find.textContaining('Exception: SOI marker missing'), findsNothing);
    expect(find.text('Copy diagnostics'), findsNothing);

    await tester.tap(find.text('Show details'));
    await tester.pump();

    expect(find.textContaining('Failure: modelLoad'), findsOneWidget);
    expect(
      find.textContaining('Exception: SOI marker missing'),
      findsOneWidget,
    );
    expect(find.text('Copy diagnostics'), findsOneWidget);
  });

  testWidgets(
      'SplashScreen offers reset cached install for model load failure',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.error,
        message: 'Model could not be opened',
        failureKind: GemmaStartupFailureKind.modelLoad,
        source: ModelSourceConfig(
          kind: ModelSourceKind.network,
          origin: ModelSourceOrigin.envUrl,
          location: 'https://cdn.example.com/gemma.task',
          label: 'Managed download',
        ),
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(find.text('Reset cached install'), findsOneWidget);

    await tester.tap(find.text('Reset cached install'));
    await tester.pump();
    expect(notifier.resetCachedInstallCalled, isTrue);
  });

  testWidgets(
      'SplashScreen offers reset cached install in fallback actions for network source',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.downloading,
        progress: 20,
        source: ModelSourceConfig(
          kind: ModelSourceKind.network,
          origin: ModelSourceOrigin.envUrl,
          location: 'https://cdn.example.com/gemma.task',
          label: 'Managed download',
        ),
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(find.text('Source controls'), findsOneWidget);
    expect(find.text('Reset cached install'), findsOneWidget);
  });

  testWidgets('SplashScreen offers local import recovery actions',
      (tester) async {
    final notifier = _FakeGemmaNotifier(
      const GemmaState(
        phase: GemmaPhase.error,
        message: 'Imported model missing',
        failureKind: GemmaStartupFailureKind.localModel,
        source: ModelSourceConfig(
          kind: ModelSourceKind.file,
          origin: ModelSourceOrigin.importedFile,
          location: '/tmp/imported-model.task',
          label: 'Imported local model',
        ),
      ),
    );

    await _pumpSplashScreen(tester, notifier);

    expect(find.text('Import local model'), findsOneWidget);
    expect(find.text('Use managed download'), findsOneWidget);

    await tester.tap(find.text('Import local model'));
    await tester.pump();
    expect(notifier.importLocalModelCalled, isTrue);

    await tester.tap(find.text('Use managed download'));
    await tester.pump();
    expect(notifier.useManagedDownloadCalled, isTrue);
  });
}
