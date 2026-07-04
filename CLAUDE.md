# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ghosteye is a Flutter camera app that runs on-device Gemma 3n multimodal inference via `flutter_gemma` and renders AI-generated screenplay text as a live teleprompter overlay. Three cinematic modes (NOIR, SCI-FI, SITCOM) change the system prompt persona. Camera frames never leave the device.

## Commands

```bash
make bootstrap          # flutter pub get
make verify             # flutter analyze && flutter test (run before committing)
make analyze            # flutter analyze only
make test               # flutter test only
make format             # dart format lib test tool packages/ghosteye_frame_ffi/lib
make fix                # dart fix --apply
make run-android        # flutter run -d android --dart-define-from-file=config.json
make run-ios IOS_DEVICE=<id>  # run on physical iPhone
make build-apk-debug    # verify Android native build
make build-ios-debug    # flutter build ios --debug --no-codesign
make brand-assets       # regenerate icons/launch assets from master source image
make docs-audit         # check markdown for absolute local paths
make todo               # search TODO/FIXME markers across source
make bundle-ids         # find remaining example app identifiers before release
```

To run a single test file:
```bash
flutter test test/services/frame_preprocessor_test.dart
```

To run with a managed model URL or local model path, copy `config.json.example` to `config.json` and fill in the values, then pass `--dart-define-from-file=config.json`. Runtime env vars (`GHOSTEYE_GEMMA_MODEL_URL`, `GHOSTEYE_GEMMA_MODEL_PATH`, `GHOSTEYE_GEMMA_TOKEN`) can also be passed as individual `--dart-define` flags.

**iOS**: always use a physical device. The simulator is not a reliable target for the TensorFlow Lite / MediaPipe stack used by `flutter_gemma`.

## Architecture

### App flow (routes in `lib/config/routes.dart`)

`/` LaunchGateScreen → `/onboarding` OnboardingScreen → `/setup` SplashScreen → `/director` DirectorScreen

`LaunchGateScreen` checks onboarding status and skips to `/setup` for returning users. Fresh installs see a four-step onboarding flow that ends with a managed-download/local-import setup handoff. `DirectorScreen` uses a bottom command dock with a dominant pause/resume capture control and grouped Clear, History, Export, and Tips actions.

### State management

Riverpod exclusively, all hand-written (no codegen despite `riverpod_generator` in dev deps). `lib/providers/` is the canonical source for all shared state. Services are injected into providers via `Provider<XService>` so tests can `overrideWithValue`.
- `AsyncNotifierProvider` for async lifecycles (gemma, camera, onboarding, script history)
- `StreamProvider.autoDispose` for the inference pipeline
- `NotifierProvider` for script state
- `StateProvider` for cinematic mode and capture toggle

### Model source resolution

`ModelSourceService` (`lib/services/model_source_service.dart`) resolves which model to use in this priority order:
1. Persisted imported local file (`shared_preferences` key `ghosteye.imported_model_path`)
2. `GHOSTEYE_GEMMA_MODEL_PATH` compile-time define
3. `GHOSTEYE_GEMMA_MODEL_URL` compile-time define
4. Explicit setup error if nothing is configured

Source signatures are persisted so switching source forces reinstall. Managed URLs use `flutter_gemma` network install; local files use file install with copy into app storage. `GemmaService` tracks a `GemmaRuntimeSnapshot` (backend=GPU/CPU, source, fallback flag) after successful init. Hugging Face-specific copy should only appear when the active source is actually Hugging Face.

Setup failures are classified by `classifyGemmaStartupFailure` into a `GemmaStartupFailureKind` + friendly message, and `GemmaState.diagnosticDetail` retains the raw underlying error. `SplashScreen`'s setup-failure view surfaces both a per-kind support hint and a copyable technical block (failure kind, source, raw error) behind a "Show details" expander so support/QA can diagnose without native logs.

### Inference pipeline

`inferenceProvider` (`lib/providers/inference_provider.dart`) is a `StreamProvider.autoDispose` that:
1. Gates on `cameraProvider`, `gemmaProvider`, and `onboardingProvider` all being ready. Returns `Stream.empty()` if any dependency is loading or if `directorTipsSeen != true`.
2. Subscribes to `cameraSession.sampledFrames` (adaptive-interval sampled frames from `CameraService`).
3. For each frame: preprocesses → checks staleness via `generationId` → streams tokens from `gemmaServiceProvider.generateScriptTokens` → calls `scriptProvider.notifier` to accumulate tokens.
4. Staleness is detected via `captureEnabledProvider`, the `scriptProvider.activeGenerationId`, and mode changes. Stale generations are canceled before awaiting further work.

### Frame preprocessing

`FramePreprocessor` (`lib/services/frame_preprocessor.dart`) runs in a **Dart isolate** to avoid blocking the UI thread. The factory `FramePreprocessor.worker(settings:)` creates either `DartFramePreprocessor` or `FfiFramePreprocessor` depending on `FramePreprocessorSettings.backend`.

The backend defaults to `ffi` on supported platforms (Android, iOS, macOS); `FramePreprocessor.worker` silently downgrades to `dart` if `GhosteyeFrameFfi.isSupported` is false. The active backend and settings are exposed through `framePreprocessorSettingsProvider` (`lib/providers/inference_pipeline_metrics_provider.dart`).

**FFI backend** (`packages/ghosteye_frame_ffi/`): An internal C library (`src/ghosteye_frame_ffi.c`) with a vendored `stb_image_write.h` JPEG encoder. Exports combined convert+encode functions (`ghosteye_bgra8888_to_jpeg`, `ghosteye_yuv420_to_jpeg`) so no intermediate RGB buffer is materialized in Dart. The Dart bindings in `lib/ghosteye_frame_ffi.dart` wrap these via `dart:ffi`. To regenerate the Dart FFI bindings from the header, run `dart run ffigen --config ffigen.yaml` from inside `packages/ghosteye_frame_ffi/`.

### Script parsing and history

`ScriptController` (`lib/providers/script_provider.dart`) accumulates streamed tokens into a `liveResponse`, then on `finishResponse` classifies each line into Fountain screenplay types (`slugline`, `character`, `parenthetical`, `dialogue`, `action`) and appends parsed `ScriptEntry` objects. It auto-syncs completed sessions to `ScriptHistoryService` via `_syncHistory`.

`ScriptHistoryService` / `scriptHistoryProvider` persist up to `AppConstants.maxSavedScriptSessions` (12) recent takes as JSON in `shared_preferences`. Each take also carries an optional inline base64 JPEG **thumbnail**: `inferenceProvider` hands the latest preprocessed frame to `ScriptController.rememberFrameForThumbnail`, and `syncSession` encodes it once per take via `ThumbnailEncoder` (`lib/services/thumbnail_encoder.dart`, 160px/q55) and reuses it on later syncs so the card art stays stable. Takes also carry a user **`notes`** string (edited from the take library via `scriptHistoryProvider.setNotes`) that `ScriptExportService` appends to Fountain (boneyard) and plain-text exports. Both thumbnail and notes travel inside the session JSON, so delete/clear need no extra file lifecycle.

`ScriptScrollView` (`lib/widgets/script_scroll_view.dart`) renders the teleprompter and watches `teleprompterSettingsProvider` (`lib/providers/teleprompter_settings_provider.dart`) — an in-memory `NotifierProvider<TeleprompterSettingsController, TeleprompterSettings>`. The three enum-based settings (text size → composed `TextScaler`, density → inter-line gap, pace → typewriter `charDelay`) default to the original hardcoded presentation and are edited via the `TELEPROMPTER` section of the Model Center sheet (`TeleprompterControls`).

### Pipeline metrics

`InferencePipelineMetricsNotifier` (`lib/providers/inference_pipeline_metrics_provider.dart`) records per-stage durations (frame copy, preprocessing, model input, first token, full response) in a sliding window. Metrics recording is gated behind `AppConstants.enableFramePipelineMetrics` (only `true` in debug builds).

### Constants and compile-time overrides

`lib/config/constants.dart` centralises all magic numbers and all `String/int.fromEnvironment` reads. Frame preprocessing backend, max dimension, and JPEG quality can all be overridden at build time:

```bash
flutter run --dart-define=GHOSTEYE_FRAME_PREPROCESSOR_BACKEND=dart
flutter run --dart-define=GHOSTEYE_FRAME_MAX_DIMENSION=512
flutter run --dart-define=GHOSTEYE_FRAME_JPEG_QUALITY=75
```

## Testing patterns

- Services accept dependencies via constructor parameters with defaults — tests inject fakes, no mocking framework.
- For `AsyncNotifierProvider` overrides, pass a factory returning a concrete subclass of the notifier (e.g., `cameraProvider.overrideWith(_StubNotifier.new)`).
- For service providers, use `overrideWithValue(mockService)`. Always `addTearDown(container.dispose)`.
- `SharedPreferences.setMockInitialValues({})` in setUp for persistence tests.
- **Frame preprocessor tests** (`test/services/frame_preprocessor_test.dart`) compile the native C library on macOS at test time using `cc -dynamiclib` in `setUpAll`. Tests that need the native dylib guard with `if (ffiLibraryPath == null) return;` — silently skipped on non-macOS.
- Widget tests scope finders with `find.descendant(of: find.byType(TargetWidget), matching: ...)` to avoid ambiguity with Material scaffold-level widgets.

## Key conventions

- Providers are hand-written, not generated — don't add `@riverpod` annotations.
- iOS simulator is not a valid runtime target for on-device Gemma inference.
- Mainline targets Gemma 3n E2B; Gemma 4 is a separate spike branch.
- Product name is `Ghosteye` everywhere; tagline is "Director's eye for on-device cinema."
- Mark completed items in `plan.md` as `[x]` rather than deleting them.
- Use relative links in checked-in Markdown — `make docs-audit` enforces no absolute local paths.
- When changing source precedence, onboarding behavior, or platform support: update `README.md`, `plan.md`, and `agents.md` together. When the feature backlog changes: also update `roadmap.md`.

## Repo docs

- `plan.md` — canonical checklist of completed vs pending work
- `roadmap.md` — prioritized backlog with acceptance criteria
- `agents.md` — agent handoff context, guardrails, and current blockers
- `CONTRIBUTING.md` — maintainer workflow and doc-sync rules

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
