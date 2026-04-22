# Ghosteye Agent Handoff

This file is for any future agent or engineer picking up work in this repo. It summarizes the current runtime, the important constraints, the most relevant files, and the remaining work that should stay visible.

## Repo status

- Project status: `mainline Gemma 3n source refactor, onboarding, branding pass, and session history completed`
- Confidence status: `static analysis and automated tests passing after the onboarding pass`
- Remaining execution status: `real-device validation, production rollout, and store prep still pending`
- Spike status: `Gemma 4 investigation intentionally deferred to a separate branch`

## What the app does

Ghosteye is a Flutter camera app that:

- captures live camera frames
- runs on-device multimodal Gemma inference
- turns the scene into screenplay-style text
- renders the text as a teleprompter overlay
- supports `NOIR`, `SCI-FI`, and `SITCOM` cinematic modes

## Current runtime decisions

- Flutter toolchain in mainline: `3.24.4` / Dart `3.5.4`
- Mainline inference package: `flutter_gemma 0.11.8`
- Mainline model family: Gemma 3n E2B multimodal
- Mainline platforms: Android and physical iPhone
- iOS simulator should not be treated as a trustworthy target for runtime signoff

## Architecture snapshot

1. `LaunchGateScreen` decides whether the app routes into onboarding or setup.
2. `ModelSourceService` resolves the active source and owns imported local file persistence.
3. `GemmaService` handles install/open, backend fallback, and source-aware failure classification.
4. `DirectorScreen` owns the live camera-to-screenplay experience, pause/resume controls, and the first-run tips handoff.
5. `FramePreprocessor` converts camera frames with a Dart backend by default and an optional internal FFI backend for supported platforms.
6. `ScriptController` parses Fountain-style output, while `ScriptHistoryService` persists recent takes.

## Model source rules

Ghosteye no longer assumes Hugging Face is the only delivery path.

Source resolution order is:

1. persisted imported local model path
2. `GHOSTEYE_GEMMA_MODEL_PATH`
3. `GHOSTEYE_GEMMA_MODEL_URL`
4. legacy Hugging Face fallback URL

Important behavior:

- managed URLs install via `flutter_gemma` network source
- local paths and imported files install via `flutter_gemma` file source
- imported files are copied into app documents storage
- installed source signatures are persisted so switching source forces reinstall
- Hugging Face-specific copy should only appear when the active source is actually Hugging Face

## Runtime inputs

- `GHOSTEYE_GEMMA_MODEL_URL`
  Primary managed download URL
- `GHOSTEYE_GEMMA_MODEL_PATH`
  Explicit local model file path override
- `GHOSTEYE_GEMMA_TOKEN`
  Optional token for gated model downloads
- `HUGGINGFACE_TOKEN`
  Legacy alias only

## Repo map

- `README.md`
  Public-facing overview, setup, and current feature/status summary
- `CONTRIBUTING.md`
  Maintainer workflow, validation expectations, and doc-sync rules
- `plan.md`
  Working checklist of completed vs pending work
- `roadmap.md`
  Prioritized backlog with acceptance criteria
- `Makefile`
  Common Flutter, build, diagnostics, and repo-audit commands
- `packages/ghosteye_frame_ffi/`
  Internal FFI preprocessing package used by the frame pipeline experiments

## Development commands

- `make help`
  Print the maintainer command list
- `make verify`
  Standard local verification pass
- `make run-android`
  Run the app on Android using `config.json` when present
- `make run-ios IOS_DEVICE=<physical-device-id>`
  Run the app on a physical iPhone
- `make brand-assets`
  Regenerate icons and launch assets from the Ghosteye master image
- `make todo`
  Search remaining TODO/FIXME markers
- `make bundle-ids`
  Search remaining example app identifiers before release

## Files to inspect first

- `lib/services/model_source_service.dart`
  Source resolution, local import, persistence
- `lib/services/gemma_service.dart`
  Install dispatch, runtime state, source-aware failure handling
- `lib/providers/gemma_provider.dart`
  Setup state and splash actions
- `lib/services/onboarding_service.dart`
  Persists intro/tips completion and seeds upgrade bypass for existing installs
- `lib/providers/onboarding_provider.dart`
  Shares onboarding state across the launch gate, director flow, and inference gating
- `lib/screens/launch_gate_screen.dart`
  Decides whether `/` routes to onboarding or setup
- `lib/screens/onboarding_screen.dart`
  Skippable three-page onboarding flow before model setup
- `lib/services/app_haptics.dart`
  Centralizes system haptic feedback for onboarding, buttons, and key controls
- `lib/screens/splash_screen.dart`
  Source-specific progress, guidance, and recovery actions
- `lib/widgets/director_tips_sheet.dart`
  First-take guidance and replayable `Tips` content inside the director screen
- `lib/providers/script_history_provider.dart`
  Loads, persists, and clears recent screenplay takes
- `lib/widgets/script_history_sheet.dart`
  UI for reviewing and reopening saved takes
- `tool/generate_brand_assets.dart`
  Rebuilds the launcher icons, web icons, and native launch assets from one image
- `assets/branding/ghosteye-icon-source-ai.png`
  Source AI image used to derive the current Ghosteye brand art
- `assets/branding/ghosteye-icon-master.png`
  Current app icon master used across Flutter, Android, iOS, and web
- `README.md`
  User-facing setup and current status
- `CONTRIBUTING.md`
  Maintainer workflow and doc-sync rules
- `plan.md`
  Checklist of completed and remaining work
- `roadmap.md`
  Prioritized next-feature build order and release-readiness plan
- `Makefile`
  Common run/build/test/audit commands

## Branding notes

- Product name should be `Ghosteye` across Flutter, Android, iOS, and web.
- Keep `Director's eye for on-device cinema.` as tagline-style copy rather than the app name.
- Current icon prompt:
  `stylized eye merged with a camera shutter, noir-tech mood, deep charcoal and midnight teal base, cyan glow, restrained ember accent, no text, crisp app-icon silhouette`
- If the icon changes, regenerate derived assets instead of editing one platform manually.

## Verification state

- [x] `flutter pub get`
- [x] `flutter analyze` after branding pass
- [x] `flutter test` after branding pass
- [ ] Android hardware validation
- [ ] iPhone hardware validation
- [ ] Production managed model hosting
- [ ] Store/release metadata
- [ ] Gemma 4 spike branch

## Known publication gaps

- A top-level open-source license has not been chosen yet.
- Android/iOS still use example app identifiers and package names.
- Public screenshots, support links, privacy-policy details, and GitHub-facing metadata are still pending.
- `packages/ghosteye_frame_ffi` should remain clearly internal unless someone decides to publish it separately.

## Open work

### Hardware validation

- [ ] Verify fresh-install launch gate and intro flow on Android
- [ ] Verify fresh-install launch gate and intro flow on iPhone
- [ ] Verify managed-download first launch on Android
- [ ] Verify managed-download first launch on iPhone
- [ ] Verify first-time director tips pause/resume flow on both platforms
- [ ] Verify imported local model reuse after relaunch
- [ ] Verify reset from imported model back to managed download
- [ ] Verify GPU-to-CPU fallback behavior and messaging on real devices

### Production rollout

- [ ] Host the Gemma 3n `.task` artifact on infrastructure you control
- [ ] Decide if the managed URL is public or token-gated
- [ ] Set the production `GHOSTEYE_GEMMA_MODEL_URL`
- [ ] Decide whether the legacy Hugging Face fallback stays available in release builds

### Release polish

- [ ] Replace example bundle identifiers and package names
- [ ] Capture App Store / Play Store screenshots
- [ ] Finalize store-listing copy, privacy-policy requirements, and support links

### Gemma 4 spike

- [ ] Create a separate spike branch
- [ ] Upgrade Flutter on the spike branch
- [ ] Upgrade `flutter_gemma` on the spike branch
- [ ] Verify Gemma 4 install behavior
- [ ] Verify Android camera-to-model viability
- [ ] Verify iOS multimodal viability
- [ ] Measure model-size and startup-time impact
- [ ] Record a go/no-go recommendation

## Suggested next product work

- [ ] Export or share a take as Fountain/plain text
- [ ] Attach a representative frame thumbnail to each beat
- [ ] Add model-storage diagnostics and cache-reset controls
- [ ] Add user controls for sampling pace and responsiveness

## Recommended next order

1. Finalize repo and release basics: license decision, production app IDs, managed model hosting, and auth policy.
2. Run the real-device Android and iPhone validation matrix.
3. Capture release assets and GitHub/store metadata once the runtime path is stable.
4. Build creator workflow improvements: export/share, thumbnails, diagnostics, then pacing controls.
5. Keep Gemma 4 work isolated on a separate spike branch until it proves cross-platform viability.

## Guardrails for future work

- Keep mainline focused on Gemma 3n unless the Gemma 4 spike proves cross-platform multimodal parity.
- Do not delete completed checklist items from `plan.md`; mark them as completed instead.
- If you change source precedence, onboarding behavior, or runtime setup copy, update `README.md`, `plan.md`, and this file together.
- If you update branding, regenerate platform assets via `tool/generate_brand_assets.dart` and update the brand prompt here if the visual direction changes.
- If you add new setup flows, extend tests before changing the docs.
