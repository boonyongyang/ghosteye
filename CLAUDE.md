# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ghosteye is a Flutter camera app that runs on-device Gemma 3n multimodal inference via `flutter_gemma` and renders AI-generated screenplay text as a live teleprompter overlay. Three cinematic modes (NOIR, SCI-FI, SITCOM) change the system prompt persona. Camera frames never leave the device.

## Commands

```bash
make bootstrap          # flutter pub get
make verify             # flutter analyze && flutter test
make run-android        # run with config.json dart-defines if present
make run-ios IOS_DEVICE=<id>  # physical device only
make brand-assets       # regenerate icons/launch art from master image
make docs-audit         # check markdown for absolute local paths
```

Run a single test file: `flutter test test/services/gemma_service_test.dart`

Run with environment overrides: `flutter run --dart-define-from-file=config.json`

## Architecture

### App flow (routes in `lib/config/routes.dart`)

`/` LaunchGateScreen → `/onboarding` OnboardingScreen → `/setup` SplashScreen → `/director` DirectorScreen

LaunchGateScreen checks onboarding status and skips to `/setup` for returning users. Fresh installs see a four-step onboarding flow that ends with a managed-download/local-import setup handoff.

DirectorScreen uses a bottom command dock with a dominant pause/resume capture control and grouped Clear, History, Export, and Tips actions.

### Inference pipeline

Camera frames flow through a chain coordinated by `inferenceProvider` (StreamProvider):

1. **CameraService** → raw frames via `startImageStream` at device framerate
2. **FrameSampler** → throttles to 1 frame per 1.5s with backpressure (skips if inference in-flight)
3. **FrameData.fromCameraImage** → copies plane bytes for isolate safety
4. **FramePreprocessor** → converts BGRA/YUV420 to scaled JPEG in a background isolate (Dart backend by default, optional FFI backend via `packages/ghosteye_frame_ffi`)
5. **GemmaService.generateScriptTokens** → sends image + cinematic mode prompt to `flutter_gemma`
6. **ScriptController** → parses Fountain-format tokens into typed ScriptEntry lines

### Model source resolution (`lib/services/model_source_service.dart`)

Precedence: persisted imported local model → `GHOSTEYE_GEMMA_MODEL_PATH` → `GHOSTEYE_GEMMA_MODEL_URL` → error if nothing configured. Source signatures are persisted so switching forces reinstall. Managed URLs use `flutter_gemma` network install; local files use file install with copy into app storage.

### State management

Riverpod exclusively, all hand-written (no codegen despite `riverpod_generator` in dev deps):
- `AsyncNotifierProvider` for async lifecycles (gemma, camera, onboarding, script history)
- `StreamProvider.autoDispose` for the inference pipeline
- `NotifierProvider` for script state
- `StateProvider` for cinematic mode and capture toggle

### Testing patterns

- Services accept dependencies via constructor parameters with defaults — tests inject fakes, no mocking framework
- `SharedPreferences.setMockInitialValues({})` in setUp for persistence tests
- 13 test files covering services, providers, widgets, and screens

## Key conventions

- Providers are hand-written, not generated — don't add `@riverpod` annotations
- iOS simulator is not a valid runtime target for on-device Gemma inference
- Mainline targets Gemma 3n E2B; Gemma 4 is a separate spike branch
- Product name is `Ghosteye` everywhere; tagline is "Director's eye for on-device cinema."
- When changing source precedence, onboarding, or setup copy: update `README.md`, `plan.md`, and `agents.md` together
- Mark completed items in `plan.md` as `[x]` rather than deleting them
- Use relative links in checked-in Markdown — `make docs-audit` enforces no absolute local paths

## Runtime configuration (dart-define)

| Variable | Purpose |
|---|---|
| `GHOSTEYE_GEMMA_MODEL_URL` | Primary managed model download URL |
| `GHOSTEYE_GEMMA_MODEL_PATH` | Local file path override |
| `GHOSTEYE_GEMMA_TOKEN` | Bearer token for gated downloads |
| `GHOSTEYE_FRAME_PREPROCESSOR_BACKEND` | `dart` (default) or `ffi` |
| `GHOSTEYE_FRAME_MAX_DIMENSION` | Max frame dimension, default 768 |
| `GHOSTEYE_FRAME_JPEG_QUALITY` | JPEG quality 1-100, default 88 |

## Repo docs

- `plan.md` — canonical checklist of completed vs pending work
- `roadmap.md` — prioritized backlog with acceptance criteria
- `agents.md` — agent handoff context, guardrails, and current blockers
- `CONTRIBUTING.md` — maintainer workflow and doc-sync rules
