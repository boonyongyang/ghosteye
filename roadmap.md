# Ghosteye Roadmap

This file turns the current backlog into an execution order. Use it when choosing the next feature to build, and keep the checkboxes current as work lands.

## Current product state

- Runtime foundation: `stable enough for follow-up work`
- Branding, onboarding, setup, director controls, export, library, and diagnostics: `setup workspace, setup-handoff onboarding, command dock, active/saved-take export, take library with frame thumbnails and shot notes, copyable setup diagnostics, Model Center source/storage controls, persisted performance and teleprompter settings, and runtime recovery hardening implemented`
- Biggest remaining risk: `real-device validation and production rollout details`
- Known engineering-health gaps: `Gemma 4 runtime hardening awaits on-device validation; dependency refresh still gated behind the toolchain move` (FFI-in-CI, bash Makefile, CI docs-audit, preference persistence, logic-bearing widget tests including onboarding_screen, rendered UI screenshots, and the Dart-vs-FFI benchmark now addressed)
- Recommended next phase: `release readiness first, creator workflow second`

## Priority 0: Ship-readiness

These items should happen before broad external testing or store submission.

- [x] Finalize public repo basics
  Acceptance criteria: a top-level license is chosen, `RELEASE_CHECKLIST.md` stays current, the README stays public-facing with relative repo links, no obvious scaffold/package docs remain in the public tree, GitHub verification is enabled, and the internal FFI package stays clearly documented as internal-only
- [x] Choose the production Android application ID and iOS bundle ID
  Acceptance criteria: no `com.example.ghosteye` identifiers remain in shipping configs
- [ ] Host the Gemma 4 E2B `.litertlm` artifact on production infrastructure
  Acceptance criteria: a stable managed URL exists and is documented in `config.json.example` or deployment docs
- [ ] Decide the managed-download auth policy
  Acceptance criteria: app behavior is defined for public download, bearer-token gating, and missing-source recovery guidance
- [ ] Validate Android first-run setup on physical hardware
  Acceptance criteria: managed download succeeds, relaunch reuse works, imported local model works, reset-to-managed works
- [ ] Validate iPhone first-run setup on physical hardware
  Acceptance criteria: same validation flow as Android, plus GPU-to-CPU fallback messaging is confirmed
- [ ] Prepare store metadata
  Acceptance criteria: screenshots, support URL, privacy-policy plan, and listing copy are ready. Doc-quality UI screenshots now regenerate from the real widget tree via `make screenshots` (see [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md)); store listings additionally need on-device captures showing the live camera feed and real model output.

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
- Saved takes show a visual reference for the captured scene. Thumbnails are derived once per take from the already-preprocessed frame JPEG and stored with the take.

### 3.5 Shot notes

- [x] Add a lightweight local shot-notes field to each take
- [x] Include shot notes in Fountain and plain-text exports

Acceptance criteria:
- Notes stay local, remain attached to the take, and are included only when the user exports the take.

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
- [x] Persist the selected performance preset and teleprompter display settings locally

Acceptance criteria:
- The user can choose between slower richer output and faster lighter output.

### 6. Setup observability

- [x] Improve error surfaces for downloads, imports, and backend fallback
- [x] Add a compact, copyable debug detail view for setup failures

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
- [x] `onboarding_screen` widget coverage — the deferral said "revisit if the flow changes"; the Flutter upgrade spike supplied a stronger reason. `onboarding_screen.dart` carries **20 of the 49 `withOpacity` call sites**, making it the densest single file in the upgrade diff, while its only coverage was four router-level tests in `app_router_test` — one of which was the spike's sole failure. Now covered by `test/widgets/onboarding_screen_test.dart`, which targets the logic (paging state, the Back affordance appearing only after page 0, the last-page `Start setup` swap, and the `_submitting` double-submit guard) rather than the decorative widget tree.

Acceptance criteria:
- A doc with an absolute local path fails CI (docs-audit step added); `make verify` runs under `/bin/bash` (zsh install step removed); the four logic-bearing widgets above have behavior coverage, as does `onboarding_screen`.

### 11. Dependency and toolchain refresh

- [x] Triage the outdated packages (`flutter pub outdated`)
- [x] Evaluate a Flutter upgrade from 3.24.4 (Oct 2024) on a branch — this is also prerequisite work for the Gemma 4 spike
- [ ] Decide whether to take the upgrade (needs on-device validation — see below)

Triage finding (2026-07-09, Flutter 3.24.4): **no safe in-isolation bump is available.** Every *direct* dependency in `pubspec.yaml` (flutter_gemma, flutter_riverpod, go_router, camera, google_fonts, image, shared_preferences, share_plus, url_launcher, …) is already at its latest version resolvable under the pinned SDK — none appear in `flutter pub outdated`. The remaining ~100 "outdated" entries are transitive/dev packages whose `resolvable` equals `current`; their newer `latest` versions are gated behind a Flutter SDK upgrade or major-version constraint bumps. Bumping them in isolation would either fail to resolve or force a risky major jump (e.g. `flutter_lints` 4→6 enabling new lint rules) for no product value. **Item 11 therefore collapses into the Flutter-upgrade track (Priority 3):** do the dependency refresh together with the SDK upgrade, not before it.

**Superseded (2026-09-11).** The toolchain moved to **Flutter 3.38.9 / Dart 3.10.8** alongside the Gemma 4 E2B runtime work, not to 3.44.7. The 3.44.7 spike below is kept as the record of how the upgrade cost was measured; the `flutter-upgrade-spike` branch is no longer a live plan and should not be merged.

Upgrade spike finding (2026-07-26, target Flutter 3.44.7 / Dart 3.12.2): **host-side GO, pending device validation.** Evaluated on the isolated `flutter-upgrade-spike` branch; full report in [docs/FLUTTER_UPGRADE_SPIKE.md](docs/FLUTTER_UPGRADE_SPIKE.md) (the report is kept on mainline as the decision record; the upgrade code stays on the spike branch). The decisive risk — `flutter_gemma` compatibility — clears: `flutter_gemma 0.11.8` still resolves, the `background_downloader` override holds, `flutter analyze` is clean, and the suite is **281/281**. The cost is three changes that are **mutually atomic** (none can land on 3.24.4, so it is a single PR or nothing):

1. `withOpacity` → `withValues` across **49 call sites / 13 files** — mechanical, no behavior change, but `withValues` does not exist in the 3.24.4 SDK.
2. `google_fonts ^6.2.1 → ^8.2.0` — 6.3.0 fails to *compile* on Dart 3.12 (a `const` map keyed by `FontWeight`, which the analyzer misses and the compiler front-end catches); 8.x requires Dart `^3.10.0` so it cannot resolve on 3.24.4.
3. CI `flutter-version` in `.github/workflows/verify.yml`.

One widget test (`app_router_test` → onboarding `Skip`) also needed a `pumpAndSettle()` before the tap — the tap was landing mid route-entry transition, not a hit-test regression and not a production bug. That fix is test-only and verified green on **both** SDKs, so it is the one separable piece and could land on mainline ahead of the upgrade.

**Not validated, and it is the gate:** on-device Gemma 3n inference on ARM (Android/iPhone) under 3.44.7, plus a native `build apk`/`build ios`. A hosted x64 environment cannot prove these. Do not merge the upgrade until hardware validation passes.

Acceptance criteria:
- The Flutter upgrade decision is recorded (upgrade, or stay pinned with a reason); any bumps land only with `make verify` green.

### 12. Preprocessing backend benchmark — done

- [x] Add a host-runnable benchmark comparing Dart vs FFI preprocessing (convert+encode) on representative frame sizes
- [x] Record indicative results to inform the plan.md Phase 7 decision on whether the FFI backend earns its complexity

`benchmark/preprocessing_benchmark.dart` (run with `make benchmark`; lives outside `test/` so it is not in the CI suite) times both paths on synthetic frames. Host x64 result (Flutter 3.24.4, median of 25 runs, ms):

| format | size | dart | ffi | speedup |
|---|---|---|---|---|
| bgra8888 | 1280x720 | 65.2 | 10.9 | **6.0x** |
| yuv420 | 1280x720 | 83.6 | 19.8 | **4.2x** |
| bgra8888 | 1920x1080 | 76.7 | 12.9 | **5.9x** |
| yuv420 | 1920x1080 | 95.4 | 23.4 | **4.1x** |

Directional (host CPU, not a target device), but the signal is strong and consistent: the native convert+encode path is ~4–6x faster than the Dart path. This supports **keeping** the FFI backend as the default. On-device numbers should still be captured during hardware validation to confirm the win holds on ARM.

Acceptance criteria:
- A repeatable benchmark exists with documented host-side numbers, clearly labeled as directional until device measurements exist.

## Priority 3: Research and branching work

### Gemma 4 E4B follow-up

- [ ] Create a separate spike branch
- [x] Upgrade Flutter and `flutter_gemma` for Gemma 4 E2B
- [ ] Verify install behavior, Android viability, iOS multimodal viability, and startup cost
- [ ] Record a go/no-go recommendation

The Flutter move already happened as part of the Gemma 4 E2B work (3.24.4 -> 3.38.9), so treat the remaining E4B unknowns as memory and latency on target devices rather than toolchain risk.

Rule:
- Do not expand beyond Gemma 4 E2B until the E2B path proves cross-platform multimodal parity.

## Suggested build order

1. Release readiness and physical-device validation
2. Creator workflow polish after thumbnails and shot notes
3. Gemma 4 E4B follow-up only after E2B is proven on target hardware

## Notes for future agents

- If a feature lands, mark it off here and reflect the same state in `plan.md`.
- If priorities change, reorder this file rather than deleting context.
- If a task depends on a product decision from the user, leave it unchecked and write the dependency explicitly.
- If onboarding or setup copy changes, keep the launch-gate, splash, and director tips behavior aligned in docs and tests.
- If repo-publication requirements change, keep `README.md`, `CONTRIBUTING.md`, `plan.md`, and `agents.md` aligned.
