# Ghosteye Agent Handoff

This file is for a future agent or engineer picking up work in this repo. It keeps the runtime decisions, current blockers, key files, and guardrails visible without duplicating the full checklist from `plan.md` or the future backlog from `roadmap.md`.

## Current mainline state

- Project status: `Gemma 3n setup workspace, setup-handoff onboarding, director command dock, branding pass, and session history completed`
- Confidence status: `make verify passing after the legacy-cleanup pass`
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
4. `DirectorScreen` owns the live camera-to-screenplay experience, the command dock, pause/resume controls, and the first-run tips handoff.
5. `FramePreprocessor` converts camera frames with a Dart backend by default and an optional internal FFI backend for supported platforms.
6. `ScriptController` parses Fountain-style output, while `ScriptHistoryService` persists recent takes.

## Model source rules

Source resolution order is:

1. persisted imported local model path
2. `GHOSTEYE_GEMMA_MODEL_PATH`
3. `GHOSTEYE_GEMMA_MODEL_URL`
4. explicit setup error if nothing is configured

Important behavior:

- managed URLs install via `flutter_gemma` network source
- local paths and imported files install via `flutter_gemma` file source
- imported files are copied into app documents storage
- installed source signatures are persisted so switching source forces reinstall
- the mainline app no longer hardcodes a legacy Hugging Face fallback or a `HUGGINGFACE_TOKEN` alias
- Hugging Face-specific copy should only appear when the configured managed URL itself points to Hugging Face

## Runtime inputs

- `GHOSTEYE_GEMMA_MODEL_URL`
  Primary managed download URL
- `GHOSTEYE_GEMMA_MODEL_PATH`
  Explicit local model file path override
- `GHOSTEYE_GEMMA_TOKEN`
  Optional token for gated model downloads

## Repo map

- `README.md`
  Public-facing overview, setup, and release-readiness summary
- `CONTRIBUTING.md`
  Maintainer workflow, validation expectations, and doc-sync rules
- `plan.md`
  Canonical checklist of completed vs pending work
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
  Search remaining shipping app identifiers before release
- `make docs-audit`
  Check checked-in Markdown for absolute local filesystem links

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
  Skippable four-step onboarding flow with a model-source handoff before setup
- `lib/services/app_haptics.dart`
  Centralizes system haptic feedback for onboarding, buttons, and key controls
- `lib/screens/splash_screen.dart`
  Guided setup workspace with source summary, preflight context, progress, guidance, and recovery actions
- `lib/screens/director_screen.dart`
  Live camera workspace, command dock, pause/resume control, history/export/tips actions, and first-run tips handoff
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

## Current blockers

- Production hosting for the Gemma 3n `.task` artifact and the shipping `GHOSTEYE_GEMMA_MODEL_URL`
- Final managed-download auth policy
- Android and physical-iPhone validation of the setup path
- Production Android/iOS identifiers
- License choice, support/privacy URLs, screenshots, and store metadata
- A decision on whether `packages/ghosteye_frame_ffi` stays purely internal forever or gets standalone package treatment later

## Guardrails for future work

- Keep mainline focused on Gemma 3n unless the Gemma 4 spike proves cross-platform multimodal parity.
- Keep `README.md` public-facing. Use `plan.md` for checklist state and `roadmap.md` for future backlog.
- Do not delete completed checklist items from `plan.md`; mark them as completed instead.
- If you change source precedence, onboarding behavior, or runtime setup copy, update `README.md`, `plan.md`, and this file together.
- If you update branding, regenerate platform assets via `tool/generate_brand_assets.dart` and update the brand prompt here if the visual direction changes.
- If you add new setup flows, extend tests before changing the docs.
