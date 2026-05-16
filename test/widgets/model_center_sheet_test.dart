import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/models/model_source.dart';
import 'package:ghosteye/models/performance_preset.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/providers/session_controls_provider.dart';
import 'package:ghosteye/services/gemma_service.dart';
import 'package:ghosteye/widgets/model_center_sheet.dart';

Widget _buildSheet({
  GemmaState gemmaState = const GemmaState.idle(),
  PerformancePreset initialPreset = PerformancePreset.balanced,
  VoidCallback? onReset,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      gemmaProvider.overrideWith(
        () => _FixedGemmaNotifier(gemmaState),
      ),
      performancePresetProvider.overrideWith((ref) => initialPreset),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: ModelCenterSheet(
          onResetCachedInstall: onReset ?? () {},
        ),
      ),
    ),
  );
}

class _FixedGemmaNotifier extends AsyncNotifier<GemmaState>
    implements GemmaNotifier {
  _FixedGemmaNotifier(this._state);
  final GemmaState _state;

  @override
  Future<GemmaState> build() async => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('shows Model Center heading', (tester) async {
    await tester.pumpWidget(_buildSheet());
    await tester.pump();

    expect(find.text('Model Center'), findsOneWidget);
  });

  testWidgets('shows MANAGED badge for network source', (tester) async {
    const state = GemmaState(
      phase: GemmaPhase.ready,
      activeBackend: RuntimeBackend.gpu,
      source: ModelSourceConfig(
        kind: ModelSourceKind.network,
        origin: ModelSourceOrigin.envUrl,
        location: 'https://example.com/model.bin',
        label: 'Gemma 3n E2B',
      ),
    );

    await tester.pumpWidget(_buildSheet(gemmaState: state));
    await tester.pump();

    expect(find.text('MANAGED'), findsOneWidget);
    expect(find.text('Gemma 3n E2B'), findsOneWidget);
  });

  testWidgets('shows LOCAL badge for file source', (tester) async {
    const state = GemmaState(
      phase: GemmaPhase.ready,
      activeBackend: RuntimeBackend.gpu,
      source: ModelSourceConfig(
        kind: ModelSourceKind.file,
        origin: ModelSourceOrigin.importedFile,
        location: '/var/mobile/model.bin',
        label: 'Local model',
      ),
    );

    await tester.pumpWidget(_buildSheet(gemmaState: state));
    await tester.pump();

    expect(find.text('LOCAL'), findsOneWidget);
  });

  testWidgets('shows GPU backend label', (tester) async {
    const state = GemmaState(
      phase: GemmaPhase.ready,
      activeBackend: RuntimeBackend.gpu,
    );

    await tester.pumpWidget(_buildSheet(gemmaState: state));
    await tester.pump();

    expect(find.text('GPU'), findsOneWidget);
  });

  testWidgets('shows CPU fallback note when usedFallback is true',
      (tester) async {
    const state = GemmaState(
      phase: GemmaPhase.ready,
      activeBackend: RuntimeBackend.cpu,
      usedFallback: true,
    );

    await tester.pumpWidget(_buildSheet(gemmaState: state));
    await tester.pump();

    expect(find.text('CPU'), findsOneWidget);
    expect(find.textContaining('CPU fallback'), findsOneWidget);
  });

  testWidgets('preset picker shows all three options', (tester) async {
    await tester.pumpWidget(_buildSheet());
    await tester.pump();

    expect(find.text('CINEMATIC'), findsOneWidget);
    expect(find.text('BALANCED'), findsOneWidget);
    expect(find.text('FAST'), findsOneWidget);
  });

  testWidgets('tapping a preset updates description text', (tester) async {
    await tester.pumpWidget(_buildSheet(initialPreset: PerformancePreset.balanced));
    await tester.pump();

    expect(find.text(PerformancePreset.balanced.description), findsOneWidget);

    await tester.tap(find.text('CINEMATIC'));
    await tester.pump();

    expect(find.text(PerformancePreset.cinematic.description), findsOneWidget);
    expect(
      find.text(PerformancePreset.balanced.description),
      findsNothing,
    );
  });

  testWidgets('shows privacy notice', (tester) async {
    await tester.pumpWidget(_buildSheet());
    await tester.pump();

    expect(find.textContaining('frames never leave'), findsOneWidget);
  });

  testWidgets('tapping reset calls onResetCachedInstall', (tester) async {
    var called = false;

    await tester.pumpWidget(_buildSheet(onReset: () => called = true));
    await tester.pump();

    await tester.tap(find.text('Reset cached install'));
    await tester.pump();

    expect(called, isTrue);
  });
}
