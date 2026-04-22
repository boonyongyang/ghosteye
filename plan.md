# Ghosteye Plan And Status

This file is the repo's working implementation checklist. Completed work stays checked off, and anything still pending should remain unchecked so the next person can immediately see what is left.

## Overall status

- Mainline branch status: `source-agnostic Gemma 3n delivery, onboarding, branding polish, and session history implemented`
- Verification status: `analyze and tests completed after session-history pass`
- Deployment readiness: `needs hardware validation, production hosting, and store prep`
- Gemma 4 status: `not started in mainline; separate spike still pending`

## Completed in mainline

- [x] Keep production on Gemma 3n E2B multimodal for cross-platform on-device inference
- [x] Remove the assumption that all installs must use Hugging Face
- [x] Add source-aware model resolution with this precedence:
  1. persisted imported model path
  2. `GHOSTEYE_GEMMA_MODEL_PATH`
  3. `GHOSTEYE_GEMMA_MODEL_URL`
  4. legacy Hugging Face fallback URL
- [x] Add a `ModelSourceConfig` model with source kind, origin, location, label, and optional token
- [x] Route managed URLs through `flutter_gemma` network installs
- [x] Route local files through `flutter_gemma` file installs
- [x] Persist imported local model files in app storage
- [x] Persist installed source signatures so source changes force reinstall
- [x] Add splash-screen recovery actions for `Import local model` and `Use managed download`
- [x] Make startup and inference guidance source-aware instead of always Hugging Face-specific
- [x] Update `README.md` and `config.json.example` to reflect the new setup flow
- [x] Add a repo-local `Makefile` for setup, verification, run, build, and repo-audit commands
- [x] Add `CONTRIBUTING.md` so GitHub readers can understand the local workflow and doc-sync rules
- [x] Refresh the repo docs so `README.md`, `agents.md`, and the internal FFI package docs describe the actual architecture and maintainer surfaces
- [x] Replace the default Flutter launcher icon set with Ghosteye artwork on Android, iOS, and web
- [x] Replace placeholder native launch assets with a branded Ghosteye launch screen
- [x] Align the app title and platform metadata on `Ghosteye`
- [x] Add a reusable asset-generation tool and store the master branding art in-repo
- [x] Add a skippable three-page onboarding flow before setup on fresh installs
- [x] Add persisted onboarding state with legacy-install auto-bypass
- [x] Add a one-time director tips sheet plus replayable `Tips` action
- [x] Add system haptic feedback to onboarding, buttons, selections, and key action controls
- [x] Persist recent screenplay takes locally as timestamped sessions
- [x] Add a lightweight history sheet to reopen saved takes in paused review mode
- [x] Add unit coverage for source resolution and install dispatch
- [x] Add unit coverage for onboarding persistence and legacy-install seeding
- [x] Add widget coverage for splash copy and recovery actions
- [x] Add widget coverage for launch gating and director onboarding behavior
- [x] Run `flutter pub get`
- [x] Run `flutter analyze`
- [x] Run `flutter test`

## Still to do

### Hardware validation

- [ ] Validate first-run managed download on Android hardware
- [ ] Validate first-run managed download on iPhone hardware
- [ ] Validate imported-model relaunch reuse on Android
- [ ] Validate imported-model relaunch reuse on iPhone
- [ ] Validate reset from imported local model back to managed download
- [ ] Validate GPU-to-CPU fallback messaging on real devices

### Production rollout

- [ ] Host the Gemma 3n `.task` artifact on production infrastructure
- [ ] Decide whether the managed model URL is public or token-gated
- [ ] Set the shipping `GHOSTEYE_GEMMA_MODEL_URL`
- [ ] Decide whether the legacy Hugging Face fallback stays enabled in release builds

### Repo and GitHub readiness

- [ ] Choose and add a top-level open-source license
- [ ] Decide whether `packages/ghosteye_frame_ffi` remains internal-only or needs full standalone package metadata
- [ ] Regenerate or remove stale `ghosteye_frame_ffi_bindings_generated.dart` output so it matches the current native header
- [ ] Add final GitHub About metadata and public repo media once screenshots and support URLs exist

### Release polish

- [ ] Replace example bundle identifiers and package names
- [ ] Capture release screenshots and promo imagery
- [ ] Finalize store listing copy, support URL, and privacy-policy requirements
- [ ] Decide whether the launch screen art should stay static or evolve into a fully custom native splash package
- [x] Re-run `flutter analyze`
- [x] Re-run `flutter test`

### Gemma 4 spike

- [ ] Create a separate spike branch for Gemma 4 exploration
- [ ] Upgrade Flutter on the spike branch
- [ ] Upgrade `flutter_gemma` on the spike branch
- [ ] Verify Gemma 4 install behavior
- [ ] Verify Android camera-to-model viability with Gemma 4
- [ ] Verify iOS multimodal viability with Gemma 4
- [ ] Measure model size and startup-time impact
- [ ] Record a go/no-go decision with blockers if the spike fails

## Files that currently matter most

- `lib/services/model_source_service.dart`
  Resolves source precedence, imports local files, and persists source metadata
- `lib/services/gemma_service.dart`
  Coordinates install behavior, active source tracking, and source-aware failures
- `lib/providers/gemma_provider.dart`
  Exposes source-aware setup state and splash actions
- `lib/services/onboarding_service.dart`
  Persists onboarding completion flags and seeds upgrade bypass for existing installs
- `lib/providers/onboarding_provider.dart`
  Exposes onboarding state to the launch gate, director flow, and inference gating
- `lib/screens/launch_gate_screen.dart`
  Routes fresh installs to onboarding and returning users to setup
- `lib/screens/onboarding_screen.dart`
  Shows the three-page onboarding flow before model setup
- `lib/services/app_haptics.dart`
  Centralizes system haptic patterns used across onboarding and key controls
- `lib/screens/splash_screen.dart`
  Shows source-specific progress, guidance, and fallback actions
- `lib/widgets/director_tips_sheet.dart`
  Explains the first take, mode switching, and history replay inside the director flow
- `tool/generate_brand_assets.dart`
  Rebuilds app icons, web icons, and launch assets from one master image
- `assets/branding/`
  Stores the AI source image, generated master icon, and launch-card artwork
- `lib/providers/script_history_provider.dart`
  Loads, persists, and clears saved screenplay takes
- `lib/widgets/script_history_sheet.dart`
  Presents recent takes and reopens one into paused teleprompter review
- `README.md`
  User-facing setup and status overview
- `CONTRIBUTING.md`
  Maintainer workflow, verification expectations, and doc-sync rules
- `agents.md`
  Agent handoff context, constraints, commands, and open work
- `Makefile`
  Common Flutter, build, diagnostics, and repo-audit commands
- `roadmap.md`
  Prioritized next-feature plan with acceptance criteria and build order

## Suggested feature backlog

- [ ] Export or share generated screenplay beats as Fountain/plain text
- [ ] Pair each beat with a captured frame thumbnail
- [ ] Add a settings panel for model storage, cache reset, and active-source diagnostics
- [ ] Add pace and responsiveness controls for frame sampling and inference cadence

## Notes for whoever picks this up next

- Do not treat the iOS simulator as a reliable runtime target for the current on-device stack.
- Do not mix the Gemma 4 spike into the mainline Gemma 3n branch.
- Keep the checklist above updated by converting completed items from `[ ]` to `[x]` instead of deleting them.
