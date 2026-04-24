# Ghosteye

Ghosteye is a Flutter camera app that turns the live scene into scrolling screenplay text with an on-device Gemma vision model. Frames stay on-device, the output plays like a teleprompter, and the app can shift tone across `NOIR`, `SCI-FI`, and `SITCOM` modes.

## Status

- Mainline includes setup-handoff onboarding, source-aware setup, branded launch assets, and local session history.
- The mainline runtime targets Gemma 3n on Android and physical iPhone hardware.
- Production hosting, real-device validation, release identifiers, store assets, and license selection are still in progress.
- Gemma 4 remains a separate spike, not a mainline migration target.

## Highlights

- Four-step onboarding with a setup handoff before first setup
- Guided model setup workspace with managed-download and local-model install flows
- Live camera preview with screenplay-style streaming output
- One-handed director command dock for capture, history, export, clear, and tips
- Replayable director tips and session history
- GPU-first startup with visible CPU fallback status
- Local-first runtime with no server-side frame processing

## Supported Runtime

- Android: local debug builds supported
- iPhone: physical device testing supported
- iOS simulator: not a meaningful runtime signoff target for the current on-device Gemma stack

## Quick Start

1. Copy `config.json.example` to `config.json`.
2. Set `GHOSTEYE_GEMMA_MODEL_URL` to a `.task` artifact you control.
3. Run `flutter pub get`.
4. Launch with `flutter run --dart-define-from-file=config.json`.

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
  "GHOSTEYE_GEMMA_MODEL_URL": "https://your-cdn.example.com/models/gemma-3n-E2B-it-int4.task",
  "GHOSTEYE_GEMMA_TOKEN": "optional_bearer_token_for_gated_downloads"
}
```

If the download is public, omit `GHOSTEYE_GEMMA_TOKEN`.

### Local model options

- Import a local model from the splash screen when setup fails or when you want to sideload a file into app storage.
- Use a direct local-path override for support or internal testing:

```bash
flutter run \
  --dart-define=GHOSTEYE_GEMMA_MODEL_PATH=/absolute/path/to/gemma-3n-E2B-it-int4.task
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
make verify
make run-android
make run-ios IOS_DEVICE=<physical-device-id>
make docs-audit
```

## Project Docs

- [CONTRIBUTING.md](CONTRIBUTING.md): maintainer workflow and doc-sync rules
- [plan.md](plan.md): current implementation checklist and explicit blockers
- [roadmap.md](roadmap.md): prioritized follow-up work and acceptance criteria
- [agents.md](agents.md): agent handoff with runtime decisions and guardrails

## Release Readiness

Ghosteye is not yet in public-release shape. The remaining blockers are tracked in [plan.md](plan.md) and [roadmap.md](roadmap.md), with the biggest items being production model hosting, physical-device validation, final app IDs, store assets, support/privacy links, and license selection.
