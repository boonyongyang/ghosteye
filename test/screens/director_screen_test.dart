import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/theme.dart';
import 'package:ghosteye/models/frame_data.dart';
import 'package:ghosteye/models/frame_preprocessor_settings.dart';
import 'package:ghosteye/models/inference_pipeline_metrics.dart';
import 'package:ghosteye/models/onboarding_status.dart';
import 'package:ghosteye/models/script_entry.dart';
import 'package:ghosteye/models/script_session.dart';
import 'package:ghosteye/providers/camera_provider.dart';
import 'package:ghosteye/providers/inference_pipeline_metrics_provider.dart';
import 'package:ghosteye/providers/gemma_provider.dart';
import 'package:ghosteye/providers/inference_provider.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';
import 'package:ghosteye/providers/script_export_provider.dart';
import 'package:ghosteye/providers/script_history_provider.dart';
import 'package:ghosteye/providers/session_controls_provider.dart';
import 'package:ghosteye/providers/script_provider.dart';
import 'package:ghosteye/screens/director_screen.dart';
import 'package:ghosteye/services/camera_service.dart';
import 'package:ghosteye/services/gemma_service.dart';
import 'package:ghosteye/services/script_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCameraNotifier extends CameraControllerNotifier {
  _FakeCameraNotifier(this.failure);

  final CameraFailure failure;

  @override
  Future<CameraSession> build() => Future<CameraSession>.error(failure);

  @override
  void completeInference([Duration? inferenceDuration]) {}

  @override
  Future<void> refresh() async {}
}

class _NoopCameraNotifier extends CameraControllerNotifier {
  @override
  Future<CameraSession> build() {
    return Completer<CameraSession>().future;
  }

  @override
  void completeInference([Duration? inferenceDuration]) {}

  @override
  Future<void> refresh() async {}
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

class _SeededScriptController extends ScriptController {
  _SeededScriptController(this.initialState);

  final ScriptState initialState;

  @override
  ScriptState build() => initialState;
}

class _FakeScriptHistoryNotifier extends ScriptHistoryController {
  _FakeScriptHistoryNotifier(this.sessions);

  final List<ScriptSession> sessions;

  @override
  Future<List<ScriptSession>> build() async => sessions;

  @override
  Future<void> clearAll() async {
    state = const AsyncData(<ScriptSession>[]);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    state = AsyncData(
      sessions.where((session) => session.id != sessionId).toList(),
    );
  }
}

class _FakeScriptExportService extends ScriptExportService {
  _FakeScriptExportService();

  ScriptExportFormat? sharedFormat;
  ScriptExportFormat? copiedFormat;
  String? sharedTitle;
  String? copiedTitle;

  @override
  Future<void> shareDocument({
    required ScriptExportFormat format,
    required List<ScriptEntry> entries,
    required String title,
    DateTime? capturedAt,
    String notes = '',
  }) async {
    sharedFormat = format;
    sharedTitle = title;
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
    copiedTitle = title;
  }
}

class _FakeMetricsNotifier extends InferencePipelineMetricsNotifier {
  _FakeMetricsNotifier(InferencePipelineMetrics initialState)
      : super(settings: initialState.settings) {
    state = initialState;
  }
}

class _FakeReadyCameraController extends CameraController {
  _FakeReadyCameraController()
      : super(
          const CameraDescription(
            name: 'back',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
          ResolutionPreset.high,
        ) {
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1080, 1920),
    );
  }

  @override
  Widget buildPreview() {
    return const ColoredBox(color: Colors.black);
  }
}

Future<ProviderContainer> _pumpDirectorScreen(
  WidgetTester tester, {
  required InferenceStatusState inferenceStatus,
  required bool captureEnabled,
  required ScriptState scriptState,
  required GemmaState gemmaState,
  InferencePipelineMetrics? pipelineMetrics,
  CameraFailure? cameraFailure,
  AsyncValue<CameraSession>? cameraSessionState,
  OnboardingStatus onboardingStatus = const OnboardingStatus(
    introComplete: true,
    directorTipsSeen: true,
  ),
  ScriptExportService? exportService,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final container = ProviderContainer(
    overrides: <Override>[
      cameraProvider.overrideWith(
        () => cameraSessionState == null
            ? _FakeCameraNotifier(
                cameraFailure ??
                    const CameraFailure(
                      kind: CameraFailureKind.permissionDeniedPermanently,
                      message: 'Camera access was denied earlier.',
                    ),
              )
            : _NoopCameraNotifier(),
      ),
      if (cameraSessionState != null)
        cameraSessionViewProvider.overrideWith((ref) => cameraSessionState),
      gemmaProvider.overrideWith(() => _FakeGemmaNotifier(gemmaState)),
      onboardingProvider.overrideWith(
        () => _FakeOnboardingController(onboardingStatus),
      ),
      inferenceProvider.overrideWith(
        (ref) => const Stream<InferenceEvent>.empty(),
      ),
      inferenceStatusProvider.overrideWith((ref) => inferenceStatus),
      inferencePipelineMetricsProvider.overrideWith(
        (ref) => _FakeMetricsNotifier(
          pipelineMetrics ??
              const InferencePipelineMetrics(
                settings: FramePreprocessorSettings(
                  backend: FramePreprocessorBackend.dart,
                  maxDimension: 768,
                  jpegQuality: 88,
                ),
              ),
        ),
      ),
      captureEnabledProvider.overrideWith((ref) => captureEnabled),
      scriptProvider.overrideWith(() => _SeededScriptController(scriptState)),
      scriptHistoryProvider.overrideWith(
        () => _FakeScriptHistoryNotifier(
          <ScriptSession>[
            ScriptSession(
              id: 'saved-1',
              createdAt: DateTime.utc(2026, 4, 21, 10),
              updatedAt: DateTime.utc(2026, 4, 21, 10, 30),
              entries: const <ScriptEntry>[
                ScriptEntry(
                  type: ScriptEntryType.slugline,
                  text: 'INT. CAB - NIGHT',
                ),
                ScriptEntry(
                  type: ScriptEntryType.action,
                  text: 'Streetlight fractures over the windshield.',
                ),
              ],
            ),
          ],
        ),
      ),
      scriptExportServiceProvider.overrideWithValue(
        exportService ?? ScriptExportService(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const DirectorScreen(),
      ),
    ),
  );
  await tester.pump();

  return container;
}

void main() {
  testWidgets('DirectorScreen shows paused status and permission recovery',
      (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: false,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Capture is paused'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.text('Retry Camera'), findsOneWidget);
  });

  testWidgets('DirectorScreen shows processing state and CPU fallback badge',
      (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(
        activity: InferenceActivity.processing,
      ),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.cpu,
        usedFallback: true,
      ),
    );

    expect(find.text('CPU THINKING'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Capture is live'), findsOneWidget);
    expect(find.text('DEV METRICS'), findsOneWidget);

    await tester.tap(find.text('DEV METRICS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Pipeline Diagnostics'), findsOneWidget);
    expect(find.text('Model backend'), findsOneWidget);
    expect(find.text('CPU (fallback)'), findsOneWidget);
  });

  testWidgets('DirectorScreen shows rolling preprocessing metrics in debug UI',
      (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
      pipelineMetrics: const InferencePipelineMetrics(
        settings: FramePreprocessorSettings(
          backend: FramePreprocessorBackend.ffi,
          maxDimension: 640,
          jpegQuality: 82,
        ),
        frameCopy: DurationMetricSnapshot(
          median: Duration(milliseconds: 4),
          sampleCount: 4,
        ),
        preprocessing: DurationMetricSnapshot(
          median: Duration(milliseconds: 11),
          sampleCount: 4,
        ),
        modelInput: DurationMetricSnapshot(
          median: Duration(milliseconds: 18),
          sampleCount: 4,
        ),
        firstToken: DurationMetricSnapshot(
          median: Duration(milliseconds: 320),
          sampleCount: 4,
        ),
        fullResponse: DurationMetricSnapshot(
          median: Duration(milliseconds: 2100),
          sampleCount: 4,
        ),
      ),
    );

    // Metrics now live in the debug sheet — open it first.
    expect(find.text('DEV METRICS'), findsOneWidget);
    await tester.tap(find.text('DEV METRICS'));
    await tester.pumpAndSettle();

    expect(find.text('Pipeline Diagnostics'), findsOneWidget);
    expect(find.textContaining('FFI 640px Q82'), findsOneWidget);
    expect(find.text('4 ms med'), findsOneWidget);
    expect(find.text('11 ms med'), findsOneWidget);
    expect(find.text('18 ms med'), findsOneWidget);
    expect(find.text('320 ms med'), findsOneWidget);
    expect(find.text('2100 ms med'), findsOneWidget);
  });

  testWidgets(
      'DirectorScreen shows first-run tips once and resumes capture after dismiss',
      (tester) async {
    final readySession = CameraSession(
      controller: _FakeReadyCameraController(),
      sampledFrames: const Stream<FrameData>.empty(),
      sampler: FrameSampler(interval: const Duration(milliseconds: 1500)),
      sampleInterval: const Duration(milliseconds: 1500),
    );

    final container = await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
      cameraSessionState: AsyncData(readySession),
      onboardingStatus: const OnboardingStatus(
        introComplete: true,
        directorTipsSeen: false,
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Before the first take'), findsOneWidget);
    expect(container.read(captureEnabledProvider), isFalse);

    await tester.ensureVisible(find.text('Start shooting'));
    await tester.tap(find.text('Start shooting'));
    await tester.pumpAndSettle();

    expect(container.read(captureEnabledProvider), isTrue);
    expect(
      container.read(onboardingProvider).valueOrNull?.directorTipsSeen,
      isTrue,
    );
    expect(find.text('Before the first take'), findsNothing);

    await tester.pump();
    expect(find.text('Before the first take'), findsNothing);
  });

  testWidgets('DirectorScreen does not auto-show tips when camera is failing',
      (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
      onboardingStatus: const OnboardingStatus(
        introComplete: true,
        directorTipsSeen: false,
      ),
    );

    expect(find.text('Before the first take'), findsNothing);
  });

  testWidgets('DirectorScreen can reopen the tips manually', (tester) async {
    final readySession = CameraSession(
      controller: _FakeReadyCameraController(),
      sampledFrames: const Stream<FrameData>.empty(),
      sampler: FrameSampler(interval: const Duration(milliseconds: 1500)),
      sampleInterval: const Duration(milliseconds: 1500),
    );

    final container = await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
      cameraSessionState: AsyncData(readySession),
    );

    await tester.pumpAndSettle();
    expect(find.text('Before the first take'), findsNothing);

    await tester.tap(find.text('Tips'));
    await tester.pumpAndSettle();

    expect(find.text('Before the first take'), findsOneWidget);
    expect(container.read(captureEnabledProvider), isFalse);

    await tester.ensureVisible(find.text('Back to scene'));
    await tester.tap(find.text('Back to scene'));
    await tester.pumpAndSettle();

    expect(container.read(captureEnabledProvider), isTrue);
  });

  testWidgets('DirectorScreen shows error status', (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(
        activity: InferenceActivity.error,
        errorMessage: 'Backend failed',
        errorKind: InferenceFailureKind.backendInitialization,
      ),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    expect(find.text('ERROR'), findsOneWidget);
  });

  testWidgets('DirectorScreen clear resets script and later generations render',
      (tester) async {
    final container = await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(
        activity: InferenceActivity.processing,
      ),
      captureEnabled: true,
      scriptState: ScriptState(
        entries: <ScriptEntry>[
          const ScriptEntry(
            type: ScriptEntryType.action,
            text: 'Rain needles the windshield.',
          ),
        ],
      ),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    expect(find.text('THINKING'), findsOneWidget);
    expect(find.text('Rain needles the windshield.'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Rain needles the windshield.'), findsNothing);

    final scriptController = container.read(scriptProvider.notifier);
    scriptController.startResponse(42);
    scriptController.appendToken(
      generationId: 42,
      token: 'EXT. ROOFTOP - DAWN',
    );
    scriptController.finishResponse(42);

    await tester.pump();
    await tester.pump();

    expect(find.text('EXT. ROOFTOP - DAWN'), findsOneWidget);
  });

  testWidgets('DirectorScreen can reopen a saved take from history',
      (tester) async {
    final container = await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(
        entries: <ScriptEntry>[
          const ScriptEntry(
            type: ScriptEntryType.action,
            text: 'Current live take',
          ),
        ],
      ),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Take Library'), findsOneWidget);
    expect(find.text('INT. CAB - NIGHT'), findsOneWidget);

    await tester.tap(find.text('INT. CAB - NIGHT'));
    await tester.pumpAndSettle();

    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('REVIEWING SAVED TAKE'), findsOneWidget);
    expect(find.text('INT. CAB - NIGHT'), findsOneWidget);
    expect(
      find.text('Streetlight fractures over the windshield.'),
      findsOneWidget,
    );
    expect(find.text('Current live take'), findsNothing);
    expect(container.read(reviewModeProvider), isTrue);
  });

  testWidgets('DirectorScreen clears review mode when resuming capture',
      (tester) async {
    final container = await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INT. CAB - NIGHT'));
    await tester.pumpAndSettle();

    expect(find.text('REVIEWING SAVED TAKE'), findsOneWidget);
    expect(container.read(reviewModeProvider), isTrue);

    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(find.text('REVIEWING SAVED TAKE'), findsNothing);
    expect(container.read(reviewModeProvider), isFalse);
    expect(container.read(captureEnabledProvider), isTrue);
  });

  testWidgets('DirectorScreen shows empty state hint when script is empty',
      (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    expect(
      find.textContaining('Scene is live'),
      findsOneWidget,
    );
  });

  testWidgets(
      'DirectorScreen shows paused hint when capture is off and script is empty',
      (tester) async {
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(
        activity: InferenceActivity.paused,
      ),
      captureEnabled: false,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
    );

    expect(find.text('Capture paused.'), findsOneWidget);
    expect(find.textContaining('Scene is live'), findsNothing);
  });

  testWidgets('DirectorScreen exports the current take', (tester) async {
    final exportService = _FakeScriptExportService();
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(
        entries: <ScriptEntry>[
          const ScriptEntry(
            type: ScriptEntryType.action,
            text: 'Current live take',
          ),
        ],
      ),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
      exportService: exportService,
    );

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(find.text('Export take'), findsOneWidget);
    expect(find.text('Share Fountain'), findsOneWidget);

    await tester.tap(find.text('Share Fountain'));
    await tester.pumpAndSettle();

    expect(exportService.sharedFormat, ScriptExportFormat.fountain);
    expect(exportService.sharedTitle, 'Current take');
  });

  testWidgets('DirectorScreen exports a saved take from history',
      (tester) async {
    final exportService = _FakeScriptExportService();
    await _pumpDirectorScreen(
      tester,
      inferenceStatus: const InferenceStatusState(),
      captureEnabled: true,
      scriptState: ScriptState(),
      gemmaState: const GemmaState(
        phase: GemmaPhase.ready,
        activeBackend: RuntimeBackend.gpu,
      ),
      exportService: exportService,
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Export take'), findsOneWidget);
    await tester.tap(find.byTooltip('Export take').first);
    await tester.pumpAndSettle();

    expect(find.text('Export take'), findsOneWidget);
    await tester.tap(find.text('Copy Plain Text'));
    await tester.pumpAndSettle();

    expect(exportService.copiedFormat, ScriptExportFormat.plainText);
    expect(exportService.copiedTitle, 'Saved take');
  });
}
