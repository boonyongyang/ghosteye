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

    expect(find.textContaining('GHOSTEYE_GEMMA_TOKEN'), findsOneWidget);
    expect(find.textContaining('Hugging Face'), findsNothing);
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
