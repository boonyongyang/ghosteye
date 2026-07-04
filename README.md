# Ghosteye

Ghosteye is a Flutter camera app that turns the live scene into scrolling screenplay text with an on-device Gemma vision model. Frames stay on-device, the output plays like a teleprompter, and the app can shift tone across `NOIR`, `SCI-FI`, and `SITCOM` modes.

## Status

- Mainline includes setup-handoff onboarding, source-aware setup, branded launch assets, local take history with frame thumbnails, active/saved-take export, Model Center storage/source controls, performance presets, and teleprompter display controls.
- The mainline runtime targets Gemma 3n on Android and physical iPhone hardware.
- Production hosting, real-device validation, release identifiers, and store assets are still in progress.
- Gemma 4 remains a separate spike, not a mainline migration target.

## Highlights

- Four-step onboarding with a setup handoff before first setup
- Guided model setup workspace with managed-download and local-model install flows
- Live camera preview with screenplay-style streaming output
- One-handed director command dock for capture, history, export, clear, and tips
- Replayable director tips, local session history with per-take frame thumbnails and shot notes, and export/share for active or saved takes
- Model Center for active source, local storage, reset, source switching, privacy status, and pacing presets
- Teleprompter display controls for text size, line spacing, and reveal pace
- Copyable technical diagnostics on setup failures for faster support triage
- GPU-first startup with visible CPU fallback status
- Local-first runtime with no server-side frame processing

## Supported Runtime

- Android: local debug builds supported
- iPhone: physical device testing supported
- iOS simulator: not a meaningful runtime signoff target for the current on-device Gemma stack

## Quick Start

1. Run `make config-copy`.
2. Set `GHOSTEYE_GEMMA_MODEL_URL` to a `.litertlm` or `.task` artifact you control.
3. Run `make bootstrap`.
4. Launch with `make run DEVICE=<device-id>` or `make run-android`.

If no managed URL or local model is configured, Ghosteye now stops at setup and tells you to provide one instead of falling back to a hardcoded legacy source.

## Model Setup

Ghosteye resolves model sources in this order:

1. A previously imported local model file stored by the app
2. `GHOSTEYE_GEMMA_MODEL_PATH`
3. `GHOSTEYE_GEMMA_MODEL_URL`

### Recommended: managed download

Use a managed URL you control:

```json
{
  "GHOSTEYE_GEMMA_MODEL_URL": "https://your-cdn.example.com/models/gemma-3n-E2B-it-int4.litertlm",
  "GHOSTEYE_GEMMA_TOKEN": "optional_bearer_token_for_gated_downloads"
}
```

If the download is public, omit `GHOSTEYE_GEMMA_TOKEN`.

### Local model options

- Import a local model from the splash screen when setup fails or when you want to sideload a file into app storage.
- Use a direct local-path override for support or internal testing:

```bash
flutter run \
  --dart-define=GHOSTEYE_GEMMA_MODEL_PATH=/absolute/path/to/gemma-3n-E2B-it-int4.litertlm
```

Imported models are copied into app storage and reused on later launches until you switch back to the managed download path.

## Privacy

- Camera frames stay on-device.
- Gemma inference runs locally.
- Network access is only used to fetch the managed model artifact when you configure a URL source.

## Maintainer Commands

The repo ships with a `Makefile` for common setup and verification commands:

```bash
make help
make bootstrap
make config-copy
make config-check
make devices
make verify
make run DEVICE=<device-id>
make run-android
make run-ios IOS_DEVICE=<physical-device-id>
make run-local-model MODEL_PATH=/absolute/path/to/gemma-3n-E2B-it-int4.litertlm
make docs-audit
```

## Project Docs

- [CONTRIBUTING.md](CONTRIBUTING.md): maintainer workflow and doc-sync rules
- [LICENSE](LICENSE): MIT license for the repository
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md): GitHub and app-release blockers
- [docs/DEVICE_TEST_PLAN.md](docs/DEVICE_TEST_PLAN.md): physical Android/iPhone validation script
- [plan.md](plan.md): current implementation checklist and explicit blockers
- [roadmap.md](roadmap.md): prioritized follow-up work and acceptance criteria
- [agents.md](agents.md): agent handoff with runtime decisions and guardrails

## Release Readiness

Ghosteye is close to public GitHub shape, with MIT licensing, passing local verification, and GitHub Actions verification in place. The remaining app-release blockers are tracked in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md), [plan.md](plan.md), and [roadmap.md](roadmap.md), with the biggest items being production model hosting, physical-device validation, final app IDs, store assets, and support/privacy links.
