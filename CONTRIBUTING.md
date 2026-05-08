# Contributing To Ghosteye

Ghosteye is a Flutter camera app focused on on-device Gemma inference and screenplay-style output. This repo already has several planning surfaces; use them deliberately so product state, handoff context, and public docs do not drift apart.

## Repo map

- `README.md`
  Public project overview, setup flow, and current feature/status summary
- `CONTRIBUTING.md`
  Local development workflow, validation expectations, and doc-sync rules
- `plan.md`
  Working checklist of what is done vs still pending
- `roadmap.md`
  Prioritized next-step plan and acceptance criteria
- `agents.md`
  Future-agent handoff with runtime guardrails, key files, and current risks
- `packages/ghosteye_frame_ffi/README.md`
  Notes for the internal FFI preprocessing package

## Local setup

1. Install a Flutter toolchain compatible with this repo's `pubspec.yaml`.
2. Run `make config-copy` if you want a managed download URL or token-based local run config.
3. Run `make bootstrap`.
4. Run `make verify`.

If you are testing on iPhone, use a physical device. The iOS simulator is not a meaningful runtime signoff target for the current Gemma stack.

## Common commands

Use `make help` to print the command list. The main targets are:

- `make bootstrap`
  Install Flutter dependencies
- `make config-copy`
  Create `config.json` from the checked-in example when it is missing
- `make config-check`
  Confirm whether `config.json` will be passed to Flutter
- `make devices`
  List connected devices before choosing a run target
- `make analyze`
  Run static analysis
- `make test`
  Run the automated test suite
- `make verify`
  Run the standard local verification pass
- `make run DEVICE=<device-id>`
  Launch on a chosen connected device using `config.json` when present
- `make run-local-model MODEL_PATH=/absolute/path/model.litertlm`
  Launch with a local model path override instead of a managed download URL
- `make run-android`
  Launch on Android using `config.json` when present
- `make run-android-local-model MODEL_PATH=/absolute/path/model.litertlm`
  Launch Android with a local model path override
- `make run-ios IOS_DEVICE=<physical-device-id>`
  Launch on a physical iPhone
- `make run-ios-local-model IOS_DEVICE=<physical-device-id> MODEL_PATH=/absolute/path/model.litertlm`
  Launch iPhone with a local model path override
- `make logs DEVICE=<device-id>`
  Stream Flutter logs for a connected device
- `make build-apk-debug`
  Produce a debug Android build
- `make build-ios-debug`
  Produce a debug iOS build without codesigning
- `make brand-assets`
  Rebuild launcher and launch assets from the master Ghosteye image
- `make todo`
  Search for TODO/FIXME markers
- `make bundle-ids`
  Search for remaining shipping app bundle identifiers
- `make docs-audit`
  Check checked-in Markdown for absolute local filesystem links

## Validation expectations

Before landing meaningful app or setup-flow changes, run:

```bash
make verify
```

If you changed checked-in Markdown, also run:

```bash
make docs-audit
```

For source-loading, onboarding, or setup-state changes, also verify the affected device flow manually when hardware is available. The current automated suite is useful, but it does not replace real-device camera and model-install validation.

## Documentation rules

Keep these files aligned when related behavior changes:

- Update `README.md`, `plan.md`, and `agents.md` together if source precedence, onboarding behavior, runtime setup copy, or platform support changes.
- Update `README.md`, `plan.md`, `roadmap.md`, and `agents.md` together when the feature backlog meaningfully changes.
- Regenerate assets with `make brand-assets` if the Ghosteye icon or launch art changes.
- Extend tests before updating docs when adding a new setup or recovery path.
- Use relative repo links in checked-in Markdown. Do not commit absolute local filesystem paths such as `/Users/...`.

## Current contribution priorities

- Real-device Android and iPhone validation of the managed-download and imported-model flows
- Production hosting and authentication policy for the Gemma 3n `.litertlm` or `.task` artifact
- Release metadata, screenshots, support links, and privacy-policy planning
- Creator workflow improvements after release-readiness work: take library polish, frame thumbnails, diagnostics, and pacing controls

## Open-source and GitHub gaps

The repo is structurally close to being shareable, but a few publication basics are still outstanding:

- A top-level open-source license has not been chosen yet.
- Example Android/iOS application identifiers still need replacement before release.
- Store screenshots, support links, privacy-policy details, and public repo metadata are still pending.
- The internal `ghosteye_frame_ffi` package should stay clearly documented as an internal package unless you decide to publish it separately.
