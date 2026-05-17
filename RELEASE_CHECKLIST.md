# Ghosteye Release Checklist

This checklist is the release gate for making Ghosteye public on GitHub or preparing store/TestFlight/Play testing. Keep `README.md` public-facing; use this file for blocker tracking.

## Current Gate

- Repo verification: `make verify` passing on 2026-05-23.
- Markdown audit: `make docs-audit` passing on 2026-05-23.
- Diff hygiene: `git diff --check` passing on 2026-05-23.
- TODO audit: `make todo` has no current TODO/FIXME markers.
- GitHub CI: `.github/workflows/verify.yml` runs `make verify` on pushes and pull requests.
- GitHub repo: `boonyongyang/ghosteye`, currently private.

## Required Before Public GitHub Release

- [ ] Choose and add a top-level open-source license.
- [ ] Decide whether the GitHub repo should become public before app-store readiness.
- [ ] Set final GitHub About metadata, topics, and optional homepage URL.
- [ ] Confirm public docs do not expose private model URLs, tokens, local paths, or unreleased store claims.
- [ ] Keep `graphify-out/` ignored; it is generated local analysis output.

## Required Before App/TestFlight/Play Release

- [ ] Replace example app identifiers:
  - Android namespace/application ID: `com.example.ghosteye`
  - iOS bundle ID: `com.example.ghosteye`
  - Kotlin package path under `android/app/src/main/kotlin/com/example/ghosteye/`
- [ ] Configure real Android release signing instead of debug signing.
- [ ] Configure production iOS signing, team, bundle ID, and capabilities.
- [ ] Finalize production hosting for the Gemma 3n `.litertlm` or `.task` artifact.
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
