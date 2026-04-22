# Ghosteye

Ghosteye is a Flutter camera app that turns the live scene into a scrolling screenplay using an on-device Gemma vision model. The app keeps camera frames local, streams screenplay text in real time, and lets you switch between `NOIR`, `SCI-FI`, and `SITCOM` modes.

## Status

- Mainline runtime status: `source-aware Gemma delivery, first-run onboarding, and branding pass implemented`
- Mainline model path: Gemma 3n E2B multimodal
- Setup model sources: managed URL, imported local model, configured local path, legacy Hugging Face fallback
- Remaining non-code work: real-device validation, production hosting, release-store prep, Gemma 4 spike
- Next planning file: [roadmap.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/roadmap.md)

## Repo guide

- [README.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/README.md)
  Public project overview, setup flow, and current feature/status summary
- [CONTRIBUTING.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/CONTRIBUTING.md)
  Maintainer workflow, verification expectations, and GitHub-friendly repo rules
- [plan.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/plan.md)
  Working implementation checklist that should preserve completed items
- [roadmap.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/roadmap.md)
  Prioritized next-step plan and acceptance criteria
- [agents.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/agents.md)
  Future-agent handoff for runtime decisions, key files, and guardrails
- [packages/ghosteye_frame_ffi/README.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/packages/ghosteye_frame_ffi/README.md)
  Notes for the internal FFI preprocessing package

## Implementation status

- [x] Replace the repo-wide Hugging Face assumption with source-aware model delivery
- [x] Support managed download URLs through `GHOSTEYE_GEMMA_MODEL_URL`
- [x] Support explicit local model path overrides through `GHOSTEYE_GEMMA_MODEL_PATH`
- [x] Support importing a local model from the splash/setup flow
- [x] Persist imported model choice across relaunches
- [x] Make startup and inference messaging source-aware
- [x] Add unit and widget coverage for source resolution, install dispatch, and splash recovery flows
- [x] Replace default Flutter launcher icons with Ghosteye branding on Android, iOS, and web
- [x] Replace placeholder native launch assets with branded Ghosteye artwork
- [x] Align the in-app title and platform metadata on `Ghosteye`
- [x] Add a skippable three-page onboarding flow before setup
- [x] Add a one-time director tips sheet with a replayable in-app `Tips` action
- [x] Add system haptics to primary buttons, selection changes, and key in-app controls
- [x] Persist recent screenplay takes locally as timestamped sessions
- [x] Add a history sheet that reopens saved takes in paused review mode
- [ ] Validate the full setup flow on real Android hardware
- [ ] Validate the full setup flow on a real iPhone
- [ ] Configure a production managed model URL and shipping auth policy
- [ ] Capture store screenshots, listing copy, and release metadata
- [ ] Run the separate Gemma 4 compatibility spike

## Architecture snapshot

1. `LaunchGateScreen` decides whether `/` routes into onboarding or setup.
2. `ModelSourceService` resolves the active model source and manages imported local files.
3. `GemmaService` installs or opens the model, tracks backend fallback, and classifies setup/inference failures.
4. `DirectorScreen` runs the camera-to-inference flow, including first-run tips, pause/resume, and history access.
5. `FramePreprocessor` converts camera frames with a Dart backend by default and an optional internal FFI backend where supported.
6. `ScriptController` parses streamed Fountain-style output into screenplay entries and syncs saved sessions through `ScriptHistoryService`.

## Current runtime

- Android debug build is supported locally.
- iOS device build is supported locally.
- iOS simulator runtime is still not a reliable target for the current TensorFlow Lite / MediaPipe stack used by `flutter_gemma`; use a physical iPhone for meaningful runtime validation.
- Production remains on Gemma 3n E2B multimodal. Gemma 4 is intentionally left as a separate spike, not part of the mainline runtime.

## Model setup

Ghosteye now supports multiple model delivery paths. The app resolves them in this order:

1. A previously imported local model file stored by the app
2. `GHOSTEYE_GEMMA_MODEL_PATH`
3. `GHOSTEYE_GEMMA_MODEL_URL`
4. The repo's legacy Hugging Face fallback URL

This means Hugging Face is no longer required for every install. It is only relevant if you still point the app at a gated Hugging Face source.

### Recommended: managed download URL

Point the app at a URL you control:

```json
{
  "GHOSTEYE_GEMMA_MODEL_URL": "https://your-cdn.example.com/models/gemma-3n-E2B-it-int4.task",
  "GHOSTEYE_GEMMA_TOKEN": "optional_bearer_token_for_gated_downloads"
}
```

Run with:

```bash
flutter run --dart-define-from-file=config.json
```

If your managed download is public, omit `GHOSTEYE_GEMMA_TOKEN`.

### Local file override

For support, internal testing, or sideloading, you can point the app at an existing local model file:

```bash
flutter run \
  --dart-define=GHOSTEYE_GEMMA_MODEL_PATH=/absolute/path/to/gemma-3n-E2B-it-int4.task
```

You can also import a local model from the splash screen when setup fails. Ghosteye copies the selected file into its app documents directory and reuses it on later launches until you switch back to managed download.

### Legacy Hugging Face fallback

If no managed URL or local file is configured, Ghosteye falls back to the legacy Hugging Face preview URL already used by this repo.

That fallback still requires access to `google/gemma-3n-E2B-it-litert-preview` and usually needs:

```bash
flutter run --dart-define=GHOSTEYE_GEMMA_TOKEN=hf_your_token
```

`HUGGINGFACE_TOKEN` is still accepted as a legacy alias for compatibility with older `flutter_gemma` examples, but new setups should prefer `GHOSTEYE_GEMMA_TOKEN`.

## Runtime behavior

- The app now uses a launch gate: fresh installs see a skippable three-page onboarding flow before setup, while existing installs bypass it automatically.
- The splash screen now shows which source is active: managed download, imported local model, configured local model path, or legacy Hugging Face fallback.
- The in-app splash screen, native launch screens, and app icons now share the same Ghosteye artwork.
- Network installs use the configured URL source.
- Local installs use `flutter_gemma` file-based installation.
- When an imported local model is active and setup fails, the splash screen offers `Import local model` and `Use managed download` recovery actions.
- Startup and inference messaging is source-aware, so Hugging Face-specific guidance only appears when the active source is actually Hugging Face.
- The first successful director session pauses behind a one-time tips sheet, then resumes when the user taps `Start shooting`.
- Returning users can reopen the same guidance later from the director screen's `Tips` action.

## Branding assets

- Master artwork source: `assets/branding/ghosteye-icon-source-ai.png`
- Generated app icon master: `assets/branding/ghosteye-icon-master.png`
- Launch-card asset: `assets/branding/ghosteye-launch-card.png`
- Regenerate all launcher, launch, and web icons with:

```bash
dart run tool/generate_brand_assets.dart \
  --source=assets/branding/ghosteye-icon-source-ai.png
```

Current brand prompt:

- `stylized eye merged with a camera shutter, noir-tech mood, deep charcoal and midnight teal base, cyan glow, restrained ember accent, no text, crisp app-icon silhouette`

## Running

### Android

```bash
flutter run -d android --dart-define-from-file=config.json
```

If you only want to verify the native build:

```bash
flutter build apk --debug
```

### iOS

Use a physical iPhone for the current ML runtime:

```bash
flutter run -d <ios-device-id> --dart-define-from-file=config.json
```

If you only want to verify the native build:

```bash
flutter build ios --debug --no-codesign
```

## Maintainer workflow

The repo now ships with a [Makefile](/Users/boonyongyang/Development/flutterProjects/ghosteye/Makefile) so the common verification and debug commands stay discoverable:

```bash
make help
make bootstrap
make verify
make run-android
make run-ios IOS_DEVICE=<physical-device-id>
make brand-assets
make bundle-ids
```

For the broader contributor workflow and doc-sync rules, see [CONTRIBUTING.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/CONTRIBUTING.md).

## Product features in the app

- Three-page onboarding flow before setup
- Splash screen with source-aware model setup progress
- Explicit startup guidance for managed URLs, imported local files, legacy Hugging Face fallback, backend init, and network failures
- Live camera preview with teleprompter overlay
- One-time director tips sheet with replayable `Tips` action
- Camera permission recovery UI with retry and Settings handoff when iOS stops prompting
- Streaming screenplay output with typewriter animation
- Local session history for recent screenplay takes
- `NOIR`, `SCI-FI`, and `SITCOM` cinematic modes
- Pause and resume capture controls
- Clear-script control to reset the running scene
- Adaptive frame sampling when inference slows down
- GPU-first model startup with CPU fallback surfaced in runtime status/debug UI
- System haptics on onboarding paging, primary buttons, mode switching, and key action controls

## Remaining work

- [ ] Run managed-download first launch on Android hardware
- [ ] Run managed-download first launch on iPhone hardware
- [ ] Validate imported-model relaunch reuse on both platforms
- [ ] Validate switching from imported model back to managed download
- [ ] Decide production hosting and token policy for the managed model URL
- [ ] Replace example bundle identifiers and package names before release
- [ ] Capture App Store / Play Store screenshots and listing copy
- [ ] Confirm privacy-policy, support, and release metadata requirements
- [ ] Choose and add a top-level open-source license before public GitHub release
- [ ] Execute and document the Gemma 4 spike on a separate branch

## Suggested next product work

- [ ] Export a take as Fountain text, plain text, or a share sheet payload
- [ ] Attach a frame thumbnail to each generated screenplay beat
- [ ] Add a storage and model diagnostics panel for cache size, active source, and reset actions
- [ ] Add pacing controls for how often Ghosteye samples frames during inference

The prioritized order and acceptance criteria for those items now live in [roadmap.md](/Users/boonyongyang/Development/flutterProjects/ghosteye/roadmap.md).

## Verification commands

```bash
make verify
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Next step after this branch

The follow-up Gemma 4 work should happen in a separate spike branch. That spike can upgrade the Flutter toolchain and `flutter_gemma`, then answer whether Gemma 4 is actually viable for Ghosteye's cross-platform camera-to-model flow before any migration is attempted.
