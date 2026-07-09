# Ghosteye Roadmap

This file turns the current backlog into an execution order. Use it when choosing the next feature to build, and keep the checkboxes current as work lands.

## Current product state

- Runtime foundation: `stable enough for follow-up work`
- Branding, onboarding, setup, director controls, export, library, and diagnostics: `setup workspace, setup-handoff onboarding, command dock, active/saved-take export, take library with frame thumbnails, Model Center storage/source controls, performance presets, and teleprompter display controls implemented`
- Biggest remaining risk: `real-device validation and production rollout details`
- Known engineering-health gaps: `aging dependency set; onboarding_screen widget still untested` (FFI-in-CI, bash Makefile, CI docs-audit, preference persistence, and logic-bearing widget tests now addressed)
- Recommended next phase: `release readiness (user/hardware-blocked) in parallel with engineering health and preference persistence (agent-executable)`

## Priority 0: Ship-readiness

These items should happen before broad external testing or store submission.

- [x] Finalize public repo basics
  Acceptance criteria: a top-level license is chosen, `RELEASE_CHECKLIST.md` stays current, the README stays public-facing with relative repo links, no obvious scaffold/package docs remain in the public tree, GitHub verification is enabled, and the internal FFI package stays clearly documented as internal-only
- [ ] Choose the production Android application ID and iOS bundle ID
  Acceptance criteria: no `com.example.ghosteye` identifiers remain in shipping configs
- [ ] Host the Gemma 3n `.litertlm` or `.task` artifact on production infrastructure
  Acceptance criteria: a stable managed URL exists and is documented in `config.json.example` or deployment docs
- [ ] Decide the managed-download auth policy
  Acceptance criteria: app behavior is defined for public download, bearer-token gating, and missing-source recovery guidance
- [ ] Validate Android first-run setup on physical hardware
  Acceptance criteria: managed download succeeds, relaunch reuse works, imported local model works, reset-to-managed works
- [ ] Validate iPhone first-run setup on physical hardware
  Acceptance criteria: same validation flow as Android, plus GPU-to-CPU fallback messaging is confirmed
- [ ] Prepare store metadata
  Acceptance criteria: screenshots, support URL, privacy-policy plan, and listing copy are ready

## Priority 1: Creator workflow improvements

These are the most valuable features to build next because they make Ghosteye useful after the first wow moment.

### 1. Session history

- [x] Persist recent takes locally
- [x] Group screenplay beats into sessions with timestamps
- [x] Add a lightweight history view or drawer

Why it matters:
- Without history, the generated screenplay disappears too easily.
- This is the shortest path from demo to repeatable tool.

Acceptance criteria:
- A user can reopen the app and review previous takes.
- Clearing the current take does not erase saved sessions unless the user chooses that intentionally.

### 2. Export and share

- [x] Export a take as Fountain text
- [x] Export a take as plain text
- [x] Support share-sheet handoff

Why it matters:
- The app becomes more useful once screenplay output can leave the device.

Acceptance criteria:
- A saved or active take can be shared or exported in at least one structured format and one plain format.

### 3. Frame thumbnails

- [x] Attach a representative frame thumbnail to each saved take
- [x] Keep thumbnail generation lightweight enough for on-device use

Why it matters:
- The screenplay becomes easier to scan, remember, and compare later.

Acceptance criteria:
- Saved takes show a visual reference for the captured scene. Thumbnails are
  derived once per take from the already-preprocessed frame JPEG (160px, q55),
  stored inline as base64 so a take stays self-contained, and captured on the
  take's first frame so the card art stays stable.

## Priority 2: Product controls and diagnostics

These features improve trust and operational clarity once users begin relying on the app more heavily.

### 4. Model diagnostics panel

- [x] Show active source, source kind, and current backend
- [x] Show cached-model size or approximate storage usage
- [x] Add cache reset and re-download controls
- [x] Add source-switch controls for imported local files and configured-source fallback

Acceptance criteria:
- A user can understand what model Ghosteye is using and reset it without reinstalling the app.

### 5. Sampling and responsiveness controls

- [x] Expose a few pacing presets such as `Cinematic`, `Balanced`, and `Fast`
- [x] Tune frame sampling and inference cadence by preset

Acceptance criteria:
- The user can choose between slower richer output and faster lighter output.

### 6. Setup observability

- [x] Improve error surfaces for downloads, imports, and backend fallback
- [x] Add a compact debug detail view for setup failures

Acceptance criteria:
- Support and QA can diagnose setup problems without diving into native logs
  first. `GemmaState.diagnosticDetail` carries the raw underlying error, and the
  setup failure screen surfaces a copyable technical block (failure kind, active
  source, raw error) behind the "Show details" expander.

### 7. Teleprompter display controls

- [x] Add text-size control (compact/standard/large scale)
- [x] Add line-spacing/scroll-density control
- [x] Add reveal-pace control for the typewriter cadence

Acceptance criteria:
- A user can adjust how the screenplay reads without changing model behavior; controls live in the Model Center `TELEPROMPTER` section and default to the original presentation.

### 8. Preference persistence — done

- [x] Persist the selected performance preset across app restarts
- [x] Persist teleprompter display settings (text size, spacing, pace) across app restarts

Why it matters:
- `performancePresetProvider` and `teleprompterSettingsProvider` were in-memory only, so every relaunch silently discarded the user's chosen preset and display tuning — the controls felt broken to a returning user.

Acceptance criteria:
- Choosing a preset or teleprompter setting, killing the app, and relaunching restores the same choice. Both providers hydrate synchronously from a preloaded `SharedPreferences` (`ghosteye.performance_preset`, `ghosteye.teleprompter_*`, storing enum `.name`), fall back to unchanged defaults for fresh installs and unknown values, and persist on every setter.

## Priority 2.5: Engineering health

Infrastructure and test-durability work surfaced by the CI failure post-mortem and coverage audit. None of it changes product behavior; all of it reduces the chance a regression ships.

### 9. Exercise the FFI native library in CI — done

- [x] Extend the frame-preprocessor test compile step to Linux (`cc -shared -fPIC … -lm`) so the C library builds and runs on the Ubuntu CI runner
- [x] Keep the macOS `-dynamiclib` path working for local development

Why it matters:
- The native C code — including the combined convert+JPEG encoder that is now the **default** production path — was guarded by `Platform.isMacOS` and had never been compiled or executed by CI. A C-level regression would have shipped undetected.

Acceptance criteria:
- CI logs show the FFI-backend tests running (not silently skipped) on the Linux runner. Verified locally on Linux: all frame-preprocessor tests, including the FFI-backend and native-JPEG groups, compile and pass.

### 10. CI and tooling hardening

- [x] Run `make docs-audit` in the verify workflow so the no-absolute-links rule is enforced, not just documented
- [x] Make the `Makefile` bash-compatible (drop `SHELL := /bin/zsh`) so CI no longer needs the apt-get zsh install step and `make verify` works in any POSIX environment
- [x] Add widget tests for `script_scroll_view` (empty/paused states + entry rendering), `script_export_sheet` (format/notes delegation + disabled-when-empty), `inference_indicator` (status/degraded/paused label mapping), and `director_tips_sheet`
- [ ] `onboarding_screen` widget coverage — deferred: its four-step paging is large (~840 lines) and its routing outcomes are already covered by `app_router_test`; revisit if the flow changes

Acceptance criteria:
- A doc with an absolute local path fails CI (docs-audit step added); `make verify` runs under `/bin/bash` (zsh install step removed); the four logic-bearing widgets above have behavior coverage.

### 11. Dependency and toolchain refresh

- [ ] Triage the ~101 outdated packages (`flutter pub outdated`) and land safe minor/patch bumps
- [ ] Evaluate a Flutter upgrade from 3.24.4 (Oct 2024) on a branch — this is also prerequisite work for the Gemma 4 spike

Acceptance criteria:
- Dependency bumps land only with `make verify` green; the Flutter upgrade decision is recorded (upgrade, or stay pinned with a reason).

### 12. Preprocessing backend benchmark

- [ ] Add a host-runnable benchmark comparing Dart vs FFI preprocessing (convert+encode) on representative frame sizes
- [ ] Record indicative results to inform the plan.md Phase 7 decision on whether the FFI backend earns its complexity

Acceptance criteria:
- A repeatable `dart run`/test-based benchmark exists with documented host-side numbers, clearly labeled as directional until device measurements exist.

## Priority 3: Research and branching work

### Gemma 4 spike

- [ ] Create a separate spike branch
- [ ] Upgrade Flutter and `flutter_gemma` on that branch
- [ ] Verify install behavior, Android viability, iOS multimodal viability, and startup cost
- [ ] Record a go/no-go recommendation

Rule:
- Do not mix this spike into the mainline Gemma 3n branch until it proves cross-platform multimodal parity.

## Priority 4: Future candidates (post-release)

Deliberately unscheduled; revisit after release readiness.

- [ ] Take-library text search by title (filter tabs exist; free-text search does not)
- [ ] Custom cinematic presets beyond the default three modes
- [ ] Accessibility pass: semantics labels, contrast audit, large-type layout check
- [ ] Localization scaffolding (`flutter_localizations`/`intl`) — all UI copy is hardcoded English today
- [ ] Shareable export cards or thumbnail-embedded exports

## Suggested build order

1. ~~Exercise FFI native library in CI (item 9)~~ — done
2. ~~CI and tooling hardening: docs-audit + bash Makefile (item 10)~~ — done; widget-test bullet remains
3. ~~Preference persistence (item 8)~~ — done
4. ~~Widget tests for logic-bearing surfaces (item 10)~~ — done (onboarding_screen deferred)
5. Release readiness (Priority 0) — user decisions + physical hardware
6. Dependency/toolchain refresh (item 11) — feeds into the Gemma 4 spike
7. Preprocessing benchmark (item 12)
8. Gemma 4 spike

Items 6–7 need only the standard Flutter 3.24.4 toolchain (same as CI) and are executable by an agent in a hosted environment; item 5 is blocked on maintainer decisions and physical hardware.

## Notes for future agents

- If a feature lands, mark it off here and reflect the same state in `plan.md`.
- If priorities change, reorder this file rather than deleting context.
- If a task depends on a product decision from the user, leave it unchecked and write the dependency explicitly.
- If onboarding or setup copy changes, keep the launch-gate, splash, and director tips behavior aligned in docs and tests.
- If repo-publication requirements change, keep `README.md`, `CONTRIBUTING.md`, `plan.md`, and `agents.md` aligned.
