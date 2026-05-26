# Ghosteye Roadmap

This file turns the current backlog into an execution order. Use it when choosing the next feature to build, and keep the checkboxes current as work lands.

## Current product state

- Runtime foundation: `stable enough for follow-up work`
- Branding, onboarding, setup, director controls, export, library, and diagnostics: `setup workspace, setup-handoff onboarding, command dock, active/saved-take export, take library, Model Center storage/source controls, and performance presets implemented`
- Biggest remaining risk: `real-device validation and production rollout details`
- Recommended next phase: `release readiness first, creator workflow second`

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

- [ ] Attach a representative frame thumbnail to each screenplay beat or saved take
- [ ] Keep thumbnail generation lightweight enough for on-device use

Why it matters:
- The screenplay becomes easier to scan, remember, and compare later.

Acceptance criteria:
- Saved takes show a visual reference for the captured scene.

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

- [ ] Improve error surfaces for downloads, imports, and backend fallback
- [ ] Add a compact debug detail view for setup failures

Acceptance criteria:
- Support and QA can diagnose setup problems without diving into native logs first.

## Priority 3: Research and branching work

### Gemma 4 spike

- [ ] Create a separate spike branch
- [ ] Upgrade Flutter and `flutter_gemma` on that branch
- [ ] Verify install behavior, Android viability, iOS multimodal viability, and startup cost
- [ ] Record a go/no-go recommendation

Rule:
- Do not mix this spike into the mainline Gemma 3n branch until it proves cross-platform multimodal parity.

## Suggested build order

1. Release readiness
2. Frame thumbnails
3. Teleprompter controls
4. Setup observability
5. Gemma 4 spike

## Notes for future agents

- If a feature lands, mark it off here and reflect the same state in `plan.md`.
- If priorities change, reorder this file rather than deleting context.
- If a task depends on a product decision from the user, leave it unchecked and write the dependency explicitly.
- If onboarding or setup copy changes, keep the launch-gate, splash, and director tips behavior aligned in docs and tests.
- If repo-publication requirements change, keep `README.md`, `CONTRIBUTING.md`, `plan.md`, and `agents.md` aligned.
