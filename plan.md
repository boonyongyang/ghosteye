# Ghosteye Plan And Status

This file is the repo's working implementation checklist. Completed work stays checked off, and anything still pending should remain unchecked so the next person can immediately see what is left.

## Overall status

- Mainline branch status: `Gemma 3n setup workspace, setup-handoff onboarding, director command dock, public-doc cleanup, branding polish, take library with mode badges and favorites, Model Center storage/source controls, performance presets, teleprompter display controls, and debug diagnostics implemented`
- Verification status: `make verify passing on 2026-05-27 after public GitHub prep`
- Deployment readiness: `needs production app IDs, hardware validation, production model hosting, support/privacy URLs, and store prep`
- Gemma 4 status: `not started in mainline; separate spike still pending`
- Next product phase: `release readiness and frame thumbnails before broader release polish`

## Current phase readout

Ghosteye is no longer in the foundation-only phase. The main app already has a working route gate, source-aware model setup, branded launch assets, immersive onboarding, director tips, local history, and export/share for active and saved takes. The next risk is not another isolated feature; it is whether the first-run journey feels coherent, modern, trustworthy, and usable for someone who is not already familiar with local Gemma model setup.

Treat the next phase as a product-experience revamp across setup, onboarding, and the live director workspace. Keep the Gemma 3n runtime path stable while improving the way users understand, recover, control, and return to the app.

## UX revamp diagnosis

- [x] Onboarding currently explains the concept, but it does not actively guide the user through the model setup decision that follows.
- [x] Setup is still presented like a technical splash state. It needs to become a clear setup workspace with source choice, preflight checks, progress, recovery, and diagnostic detail.
- [x] The director screen is camera-first, which is good, but the controls read like debug-era action chips instead of a polished shooting console with hierarchy.
- [ ] History and export now work, but they still feel like utility sheets rather than a creator library.
- [ ] The current visual language is cinematic but narrow. It needs a more durable modern system: camera-led surfaces, cleaner typography, better motion, stronger iconography, and less reliance on generic dark gradients.
- [x] Trust signals are present in copy, with inspectable state for active model source, local storage impact, backend, privacy posture, and recovery options.

## Revamp principles

- [ ] Camera first: the live scene should stay the primary surface once setup is complete.
- [ ] Guided, not tutorial-heavy: onboarding should reduce uncertainty without becoming a manual.
- [ ] Recoverable setup: every setup path needs retry, cancel, source switch, and clear next action states.
- [ ] One-handed controls: primary capture, mode, history, and export actions should be reachable and visually prioritized.
- [ ] Source-aware trust: show what model source is active, whether it is local or managed, and what network activity is happening.
- [ ] Progressive detail: keep the default UI simple, but expose diagnostics when setup or performance fails.
- [ ] Modern but domain-specific: use the camera feed, model status, screenplay output, and brand art as the visual material instead of decorative filler.
- [ ] Device-proven: visual and setup decisions are not complete until checked on Android and physical iPhone hardware.

## Revamp execution plan

### Phase 0: Baseline and current worktree confirmation

- [x] Run `make verify` before starting implementation so the current dirty worktree has a known baseline.
- [x] Confirm whether the current export/share implementation is intended to land now.
- [x] If export/share is accepted, mark the export items complete in this file and in `roadmap.md`.
- [ ] Capture before screenshots or short screen recordings for onboarding, setup success, setup failure, director, history, and export.
- [ ] Review the app on at least one compact phone viewport before changing layout density.

Acceptance criteria:

- Baseline verification result is recorded in the handoff or commit notes.
- Existing user work is not overwritten.
- Current UX gaps are visible with screenshots or manual notes before redesign starts.

### Phase 1: Product architecture and design system

- [ ] Define the first-run journey as explicit states: launch gate, intro, model source choice, preflight, install/progress, camera permission, first take, review/export.
- [x] Replace one-off surfaces with shared components for bottom sheets, glass/dim overlays, status rows, icon actions, segmented controls, progress panels, and destructive actions.
- [ ] Revisit typography so display type stays cinematic, while setup, diagnostics, and repeated controls use a cleaner, more readable operational style.
- [x] Add a small state vocabulary for `ready`, `needs action`, `working`, `degraded`, and `failed` so setup and director indicators feel consistent.
- [ ] Reduce generic gradient/orb decoration in high-value screens and use real product signals instead: live camera, brand art, progress, model source, and screenplay preview.
- [ ] Audit contrast, text fitting, button labels, safe areas, compact-height behavior, and dynamic text scale.

Acceptance criteria:

- New setup, onboarding, and director work can reuse shared UI primitives instead of copying local styles.
- Compact mobile layouts avoid clipped text, overlapping controls, and hidden primary actions.
- The product can still look like Ghosteye without every surface using the same dark cinematic treatment.

### Phase 2: Setup workspace revamp

- [x] Replace the passive setup splash with a dedicated model setup screen.
- [x] Present the recommended path first: managed download when `GHOSTEYE_GEMMA_MODEL_URL` exists.
- [x] Keep local import as an obvious fallback, not a buried error action.
- [x] Add a preflight panel for Wi-Fi/network, storage expectation, battery/thermal note, model size when known, and privacy statement.
- [x] Show setup progress with source label, current phase, percentage when available, and a plain-language explanation of what is happening.
- [x] Add recoverable actions for retry, import another file, switch back to managed download, reset cached install, and open diagnostic details.
- [x] Preserve prior working source on failed import or canceled file picker.
- [x] Add a post-install summary before camera opens: active source, backend, CPU fallback warning if needed, and next action.
- [x] Add a developer-only detail block when no source is configured, with `config.json` and `--dart-define` guidance.

Acceptance criteria:

- A nontechnical tester can understand why setup is needed and what action is available next.
- Missing source, missing token, bad URL, network failure, unreadable local file, and backend fallback each produce a distinct, actionable state.
- The setup flow never traps the user in an undismissable dialog or unrecoverable loading state.

### Phase 3: Onboarding revamp

- [x] Move onboarding from concept slides to a guided first-run sequence that prepares the setup decision.
- [x] Keep the edge-to-edge, immersive direction, but make each page map to an actual next behavior: privacy, model prep, first take, saved/exported output.
- [x] Add a final setup handoff screen that clearly explains managed download versus local import before routing to setup.
- [x] Use brand art, product UI fragments, or camera-led motion instead of abstract decoration where possible.
- [x] Keep `Skip` available, but make skip land in the same recoverable setup workspace.
- [x] Add reduced-motion and compact-height behavior for the pager.
- [x] Keep returning-user bypass behavior intact.

Acceptance criteria:

- Fresh install goes from onboarding to setup without a conceptual drop-off.
- Returning users still bypass onboarding.
- Widget tests cover skip, next, start setup, and returning-user routing.

### Phase 4: Director workspace revamp

- [x] Replace the loose action-chip cluster with a clear bottom command dock.
- [x] Make capture state the dominant control: pause/resume should be visually unmistakable.
- [x] Move secondary actions into predictable surfaces: history/library, export/share, tips, diagnostics/settings.
- [x] Convert cinematic mode selection into a polished segmented control or mode dial with concise mode descriptions available on demand.
- [x] Add teleprompter controls for text size, scroll density, and output pace via the Model Center `TELEPROMPTER` section.
- [x] Add a review mode distinction when reopening a saved take so users know capture is paused.
- [x] Keep debug metrics out of the normal composition and expose them through a debug/diagnostics surface in debug builds.
- [x] Improve empty, paused, processing, degraded CPU fallback, and camera permission states.

Acceptance criteria:

- The primary shooting flow is usable with one hand.
- The camera view remains visually dominant.
- Users can tell at a glance whether Ghosteye is watching, paused, thinking, reviewing, or degraded.

### Phase 5: Creator workflow features

- [x] Promote history into a take library with better saved-take cards.
- [x] Add take naming or auto-generated titles from the first useful screenplay line.
- [x] Add favorite/pin support for strong takes.
- [ ] Add optional thumbnails from representative captured frames if performance allows.
- [x] Add search/filter by mode, date, and title once there is enough metadata.
- [x] Finish export/share as a first-class workflow: Fountain, plain text, clipboard, share sheet, and saved-take export.
- [ ] Consider a lightweight "shot notes" field that stays local and exports with the take.
- [ ] Consider custom cinematic presets after the default three modes feel stable.

Acceptance criteria:

- A user can return later, identify a take, reopen it, export it, and delete it intentionally.
- Export works for both the active take and saved takes.
- Library features remain local-first and do not imply cloud sync.

### Phase 6: Settings and diagnostics

- [x] Add a compact settings/model center reachable from setup and director.
- [x] Show active model source, source kind, model identifier, installed source signature, and current backend.
- [x] Show approximate cached model storage when practical.
- [x] Add cache reset and re-download controls with confirmation.
- [x] Add source-switch controls that respect the existing precedence rules.
- [x] Add a privacy/status screen that states when network is used and when frames stay on-device.
- [ ] Add support diagnostics copy for common setup failures.
- [x] Add performance presets for frame sampling and inference cadence: `Cinematic`, `Balanced`, and `Fast`.

Acceptance criteria:

- Users can understand and reset model state without reinstalling the app.
- Support can diagnose most setup failures from in-app state before native logs are needed.
- Performance presets produce measurable differences in sampling cadence or latency.

### Phase 7: Real-device validation and release polish

- [ ] Validate the full first-run flow on Android hardware.
- [ ] Validate the full first-run flow on physical iPhone hardware.
- [ ] Measure first-token time, full-response time, setup duration, and fallback frequency.
- [ ] Decide whether the FFI preprocessing backend provides enough device-level benefit to keep surfaced.
- [ ] Replace example Android/iOS identifiers.
- [ ] Finalize production model hosting and auth policy.
- [ ] Capture release screenshots only after the revamp settles.
- [ ] Update `README.md`, `roadmap.md`, `agents.md`, and `CONTRIBUTING.md` if behavior or priorities change.

Acceptance criteria:

- Setup and first-take flows pass on both target device families.
- Store screenshots reflect the actual final UX, not an intermediate implementation.
- Docs and app behavior stay aligned.

## Suggested updated build order

1. Finish recoverable setup actions and diagnostic details, especially reset cached install and explicit source switching.
2. Polish director mode, review, empty, paused, degraded, and permission states.
3. Promote history/export into a take library workflow.
4. Add settings/model diagnostics and performance presets.
5. Run hardware validation and release-readiness cleanup.

## Feature candidates to consider

- [ ] Model setup wizard with managed/local source selection
- [ ] Setup preflight checks for network, storage, battery, and privacy
- [ ] Model center with active source, backend, cache reset, and re-download
- [ ] Take library with title, mode, timestamp, favorite, thumbnail, export, and delete
- [x] Teleprompter display controls for size, density, and pace
- [ ] Performance presets that tune frame sampling and model cadence
- [ ] Optional custom cinematic modes after the default modes are polished
- [ ] Shareable export cards or thumbnails after plain text/Fountain export is stable

## Completed in mainline

- [x] Keep production on Gemma 3n E2B multimodal for cross-platform on-device inference
- [x] Remove the hardcoded legacy Hugging Face fallback and the `HUGGINGFACE_TOKEN` alias from mainline release behavior
- [x] Add source-aware model resolution with this precedence:
  1. persisted imported model path
  2. `GHOSTEYE_GEMMA_MODEL_PATH`
  3. `GHOSTEYE_GEMMA_MODEL_URL`
  4. explicit setup error if nothing is configured
- [x] Add a `ModelSourceConfig` model with source kind, origin, location, label, and optional token
- [x] Route managed URLs through `flutter_gemma` network installs
- [x] Route local files through `flutter_gemma` file installs
- [x] Persist imported local model files in app storage
- [x] Persist installed source signatures so source changes force reinstall
- [x] Add splash-screen recovery actions for `Import local model` and `Use managed download`
- [x] Replace the setup splash layout with a guided setup workspace that shows active source, preflight context, progress, and recovery actions
- [x] Make startup and inference guidance source-aware instead of always Hugging Face-specific
- [x] Update `README.md` and `config.json.example` to reflect the new setup flow
- [x] Add a repo-local `Makefile` for setup, verification, run, build, and repo-audit commands
- [x] Add `CONTRIBUTING.md` so GitHub readers can understand the local workflow and doc-sync rules
- [x] Refresh the repo docs so `README.md`, `agents.md`, and the internal FFI package docs describe the actual architecture and maintainer surfaces
- [x] Keep `README.md` public-facing and move detailed status/backlog ownership into `plan.md`, `roadmap.md`, and `agents.md`
- [x] Add a repo-level docs audit command to catch absolute local filesystem links in checked-in Markdown
- [x] Replace the default Flutter launcher icon set with Ghosteye artwork on Android, iOS, and web
- [x] Replace placeholder native launch assets with a branded Ghosteye launch screen
- [x] Align the app title and platform metadata on `Ghosteye`
- [x] Add a reusable asset-generation tool and store the master branding art in-repo
- [x] Add a skippable four-step onboarding flow before setup on fresh installs
- [x] Add a final onboarding handoff that previews managed download and local import before setup opens
- [x] Add persisted onboarding state with legacy-install auto-bypass
- [x] Add a one-time director tips sheet plus replayable `Tips` action
- [x] Replace loose director action chips with a bottom command dock and dominant capture control
- [x] Add teleprompter display controls for text size, line spacing, and reveal pace in the Model Center sheet
- [x] Add system haptic feedback to onboarding, buttons, selections, and key action controls
- [x] Persist recent screenplay takes locally as timestamped sessions
- [x] Add a lightweight history sheet to reopen saved takes in paused review mode
- [x] Add export/share for active and saved takes as Fountain or plain text through share sheet and clipboard actions
- [x] Remove the internal FFI package example app and unused generated binding artifacts
- [x] Add unit coverage for source resolution and install dispatch
- [x] Add unit coverage for onboarding persistence and legacy-install seeding
- [x] Add widget coverage for splash copy and recovery actions
- [x] Add widget coverage for launch gating and director onboarding behavior
- [x] Add unit and widget coverage for export/share formatting and active/saved-take export actions
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

- [ ] Host the Gemma 3n `.litertlm` or `.task` artifact on production infrastructure
- [ ] Decide whether the managed model URL is public or token-gated
- [ ] Set the shipping `GHOSTEYE_GEMMA_MODEL_URL`

### Repo and GitHub readiness

- [x] Add GitHub Actions verification for pushes and pull requests
- [x] Add `RELEASE_CHECKLIST.md` as the focused release gate
- [x] Choose and add a top-level open-source license
- [ ] Choose the production Android application ID and iOS bundle ID
- [ ] Decide whether `packages/ghosteye_frame_ffi` remains internal-only or needs full standalone package metadata
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
  Shows the four-step onboarding flow and model-source handoff before setup
- `lib/services/app_haptics.dart`
  Centralizes system haptic patterns used across onboarding and key controls
- `lib/screens/splash_screen.dart`
  Shows the guided setup workspace, source summary, preflight context, progress, guidance, and fallback actions
- `lib/widgets/director_tips_sheet.dart`
  Explains the first take, mode switching, and history replay inside the director flow
- `lib/screens/director_screen.dart`
  Owns the camera workspace, command dock, pause/resume control, history/export/tips actions, and first-run tips handoff
- `tool/generate_brand_assets.dart`
  Rebuilds app icons, web icons, and launch assets from one master image
- `assets/branding/`
  Stores the AI source image, generated master icon, and launch-card artwork
- `lib/providers/script_history_provider.dart`
  Loads, persists, and clears saved screenplay takes
- `lib/widgets/script_history_sheet.dart`
  Presents recent takes and reopens one into paused teleprompter review
- `lib/services/script_export_service.dart`
  Builds Fountain/plain-text exports and dispatches share or clipboard actions
- `lib/widgets/script_export_sheet.dart`
  Presents active-take and saved-take export actions in the current worktree
- `lib/widgets/model_center_sheet.dart`
  Shows active source, backend, privacy status, reset action, and performance presets
- `lib/widgets/debug_metrics_sheet.dart`
  Keeps pipeline timing and backend diagnostics behind a debug-only director sheet
- `lib/config/theme.dart`
  Owns the current dark visual system and typography decisions that need revamp scrutiny
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

## Near-term feature backlog

- [x] Verify and land the current export/share workflow for active and saved takes
- [ ] Pair each saved take with a captured frame thumbnail when performance permits
- [x] Add a model center for storage, cache reset, active-source diagnostics, and source switching
- [x] Add pace and responsiveness controls for frame sampling and inference cadence
- [x] Add teleprompter display controls for text size, density, and reveal pace
- [ ] Add take naming, favorites, and lightweight filtering after the library surface is redesigned

## Notes for whoever picks this up next

- Do not treat the iOS simulator as a reliable runtime target for the current on-device stack.
- Do not mix the Gemma 4 spike into the mainline Gemma 3n branch.
- Keep the checklist above updated by converting completed items from `[ ]` to `[x]` instead of deleting them.
