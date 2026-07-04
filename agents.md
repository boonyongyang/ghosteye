# Ghosteye Agent Handoff

This file is for a future agent or engineer picking up work in this repo. It keeps the runtime decisions, current blockers, key files, and guardrails visible without duplicating the full checklist from `plan.md` or the future backlog from `roadmap.md`.

## Current mainline state

- Project status: `Gemma 3n setup workspace, setup-handoff onboarding, director command dock, branding pass, take library, Model Center storage/source controls, performance presets, teleprompter display controls, debug diagnostics, and export/share completed`
- Confidence status: `make verify passing on 2026-05-27 after public GitHub prep`
- Remaining execution status: `real-device validation, production rollout, and store prep still pending`
- Spike status: `Gemma 4 investigation intentionally deferred to a separate branch`

## What the app does

Ghosteye is a Flutter camera app that:

- captures live camera frames
- runs on-device multimodal Gemma inference
- turns the scene into screenplay-style text
- renders the text as a teleprompter overlay
- exports active or saved takes as Fountain or plain text through share and clipboard actions
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
7. `ScriptExportService` builds Fountain/plain-text exports for active and saved takes.
8. `ModelCenterSheet` exposes source/backend/storage/privacy/reset state, source-switch controls, and performance presets, while `DebugMetricsSheet` keeps pipeline timing out of the normal director composition.

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
- Supported local/imported file extensions:
  `.litertlm`, `.task`, `.bin`, and `.tflite`

## Repo map

- `README.md`
  Public-facing overview, setup, and release-readiness summary
- `LICENSE`
  MIT license for the repository
- `CONTRIBUTING.md`
  Maintainer workflow, validation expectations, and doc-sync rules
- `RELEASE_CHECKLIST.md`
  Focused release gate for GitHub publication and app-store/TestFlight/Play prep
- `docs/DEVICE_TEST_PLAN.md`
  Physical Android/iPhone validation script for setup, director, export, and recovery flows
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
- `make config-copy`
  Create `config.json` from the checked-in template when missing
- `make config-check`
  Show whether `config.json` will be passed into Flutter
- `make devices`
  List connected devices before choosing a run target
- `make verify`
  Standard local verification pass
- `make run DEVICE=<device-id>`
  Run on a chosen connected device using `config.json` when present
- `make run-local-model MODEL_PATH=/absolute/path/model.litertlm`
  Run with a local model file override
- `make run-android`
  Run the app on Android using `config.json` when present
- `make run-android-local-model MODEL_PATH=/absolute/path/model.litertlm`
  Run Android with a local model file override
- `make run-ios IOS_DEVICE=<physical-device-id>`
  Run the app on a physical iPhone
- `make run-ios-local-model IOS_DEVICE=<physical-device-id> MODEL_PATH=/absolute/path/model.litertlm`
  Run iPhone with a local model file override
- `make logs DEVICE=<device-id>`
  Stream Flutter logs from a connected device
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
- `lib/models/app_status.dart`
  Shared setup/director status vocabulary for ready, needs-action, working, degraded, and failed states
- `lib/widgets/glass_surface.dart`
  Shared glass panel and pill primitives used by onboarding and future overlay controls
- `lib/widgets/diagnostic_block.dart`
  Shared inline diagnostic/help block for setup and future model-center detail
- `lib/widgets/section_block.dart`
  Shared titled content block for setup panels and future settings/library surfaces
- `lib/widgets/status_panel.dart`
  Shared status-accented panel for setup progress, errors, and post-install summaries
- `lib/widgets/status_row.dart`
  Shared icon/title/detail row used in setup source and preflight panels
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
- `lib/providers/script_export_provider.dart`
  Provides the export service used by director and history surfaces
- `lib/services/script_export_service.dart`
  Builds Fountain/plain-text exports and dispatches share or clipboard actions
- `lib/widgets/script_export_sheet.dart`
  UI for exporting the current take or a saved take
- `lib/widgets/model_center_sheet.dart`
  UI for source/backend/privacy/reset state and performance preset controls
- `lib/widgets/debug_metrics_sheet.dart`
  Debug-only sheet for sampler, preprocessor, backend, and inference timing metrics
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

- Production hosting for the Gemma 3n `.litertlm` or `.task` artifact and the shipping `GHOSTEYE_GEMMA_MODEL_URL`
- Final managed-download auth policy
- Android and physical-iPhone validation of the setup path
- Production Android/iOS identifiers
- Support/privacy URLs, screenshots, and store metadata
- A decision on whether `packages/ghosteye_frame_ffi` stays purely internal forever or gets standalone package treatment later

## Guardrails for future work

- Keep mainline focused on Gemma 3n unless the Gemma 4 spike proves cross-platform multimodal parity.
- Keep `README.md` public-facing. Use `plan.md` for checklist state and `roadmap.md` for future backlog.
- Do not delete completed checklist items from `plan.md`; mark them as completed instead.
- If you change source precedence, onboarding behavior, or runtime setup copy, update `README.md`, `plan.md`, and this file together.
- If you update branding, regenerate platform assets via `tool/generate_brand_assets.dart` and update the brand prompt here if the visual direction changes.
- If you add new setup flows, extend tests before changing the docs.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
