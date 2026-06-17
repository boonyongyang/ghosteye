# Ghosteye Release Checklist

This checklist is the release gate for making Ghosteye public on GitHub or preparing store/TestFlight/Play testing. Keep `README.md` public-facing; use this file for blocker tracking.

## Current Gate

- Repo verification: `make verify` passing on 2026-06-03.
- Markdown audit: `make docs-audit` passing on 2026-06-03.
- Diff hygiene: `git diff --check` passing on 2026-06-03.
- TODO audit: `make todo` has no current TODO/FIXME markers.
- Device discovery: `make devices` passing on 2026-06-03; physical iPhone targets are visible, Android hardware is not currently visible.
- GitHub CI: `.github/workflows/verify.yml` runs `make verify` on pushes and pull requests.
- Device testing: `docs/DEVICE_TEST_PLAN.md` documents the required physical Android/iPhone validation pass.
- GitHub repo: `boonyongyang/ghosteye`, public.

## Required Before Public GitHub Release

- [x] Choose and add a top-level open-source license.
- [x] Decide whether the GitHub repo should become public before app-store readiness.
- [x] Set final GitHub About metadata, topics, and optional homepage URL.
- [x] Confirm public docs do not expose private model URLs, tokens, local paths, or unreleased store claims.
- [x] Keep `graphify-out/` ignored; it is generated local analysis output.

## Required Before App/TestFlight/Play Release

- [x] Replace example app identifiers:
  - Android namespace/application ID: `com.boonyongyang.ghosteye`
  - iOS bundle ID: `com.boonyongyang.ghosteye`
  - Kotlin package path under `android/app/src/main/kotlin/com/boonyongyang/ghosteye/`
- [ ] Configure real Android release signing instead of debug signing.
- [ ] Configure production iOS signing, team, bundle ID, and capabilities.
- [ ] Decide whether production iOS model runs need memory-limit entitlements re-enabled with a paid team profile.
- [ ] Finalize production hosting for the Gemma 4 E2B `.litertlm` artifact.
- [ ] Decide managed-download auth behavior for public URLs, bearer-token URLs, and missing-source recovery.
- [ ] Validate first-run setup on physical Android hardware:
  - managed download
  - relaunch reuse
  - local model import
  - reset back to configured source
- [ ] Validate first-run setup on physical iPhone hardware:
  - managed download
  - relaunch reuse
  - local model import
  - reset back to configured source
  - GPU-to-CPU fallback messaging
- [ ] Capture release screenshots only after final hardware validation.
- [ ] Prepare support URL, privacy-policy URL, listing copy, and store screenshots.

## Useful Commands

```bash
make verify
make docs-audit
make todo
make bundle-ids
make config-check
make devices
```
