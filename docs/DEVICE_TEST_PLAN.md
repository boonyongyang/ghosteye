# Ghosteye Device Test Plan

Use this plan before TestFlight, Play internal testing, or broad public demos. Automated tests prove the Flutter surface and service contracts; this plan proves the model, camera, permissions, storage, and export flows on real hardware.

## Prerequisites

- A clean checkout on `main`
- Flutter `3.24.4`
- One Android phone with camera access
- One physical iPhone with camera access
- A reachable Gemma 3n `.litertlm` or `.task` URL, or a local model file for sideload testing
- `config.json` created from `config.json.example` when testing managed download

Run the local gate first:

```bash
make bootstrap
make config-check
make verify
make docs-audit
make todo
make devices
```

Expected result:

- `make verify` passes
- `make docs-audit` reports no absolute local Markdown links
- `make todo` prints no TODO/FIXME markers
- `make devices` shows the target Android/iPhone device IDs

## Android Managed-Download Flow

1. Create or update `config.json` with `GHOSTEYE_GEMMA_MODEL_URL`.
2. Omit `GHOSTEYE_GEMMA_TOKEN` if the URL is public.
3. Run:

   ```bash
   make run-android
   ```

4. On a fresh install, confirm onboarding appears before setup.
5. Tap through onboarding and start setup.
6. Confirm setup shows the managed source, preflight notes, progress, and recovery actions.
7. Allow camera permission when prompted.
8. Confirm the director screen opens with live camera preview.
9. Wait for the first screenplay output.
10. Confirm pause/resume changes the capture state clearly.
11. Switch between `NOIR`, `SCI-FI`, and `SITCOM`.
12. Open Model Center and confirm source, backend, storage/privacy copy, and performance presets.
13. Relaunch the app and confirm the installed model is reused without a full reinstall.

Pass criteria:

- Setup completes without an unrecoverable loading state.
- First screenplay output appears from live camera frames.
- Relaunch reuses the installed model.
- Model Center reports the expected managed source.

## Android Local-Model Import Flow

1. Put a supported model file on the Android device or make it available through the file picker.
2. Run the app with no managed URL, or use Model Center/setup recovery to switch source.
3. Choose local import.
4. Pick a `.litertlm`, `.task`, `.bin`, or `.tflite` file.
5. Confirm the file imports into app storage.
6. Complete setup and reach the director screen.
7. Relaunch the app and confirm the imported source is reused.
8. Use reset or source switch to return to the managed URL.

Pass criteria:

- Bad or canceled file selections do not destroy the previous working source.
- Imported local model survives relaunch.
- Reset/source switch returns to the configured managed source.

## iPhone Managed-Download Flow

1. Connect a physical iPhone. Do not use the iOS simulator for signoff.
2. Confirm the device ID:

   ```bash
   make devices
   ```

3. Run:

   ```bash
   make run-ios IOS_DEVICE=<physical-device-id>
   ```

4. Repeat the Android managed-download flow.
5. Watch for GPU startup or CPU fallback messaging.
6. Confirm fallback messaging is visible and understandable if the app falls back to CPU.

Pass criteria:

- Physical iPhone reaches the director screen.
- First screenplay output appears.
- GPU/CPU backend state is visible through setup summary or Model Center.
- CPU fallback is understandable and not presented as a fatal failure.

## iPhone Local-Model Import Flow

1. Make the model file available through Files/iCloud/local device storage.
2. Start with no configured source or use the source-switch controls.
3. Import the local model file.
4. Confirm setup completes.
5. Relaunch and confirm the imported model persists.
6. Reset or switch back to the managed source.

Pass criteria:

- Local import works through the iOS file picker.
- Relaunch reuse works.
- Reset/source switch works.

## Director Workflow Regression Pass

Run this once on each platform after setup succeeds:

1. Generate at least one take.
2. Pause capture.
3. Resume capture.
4. Clear the active screenplay.
5. Generate a second take.
6. Open Take Library.
7. Reopen a saved take and confirm review mode is obvious.
8. Favorite a take.
9. Filter or search in the library.
10. Export the active take as Fountain.
11. Export a saved take as plain text.
12. Copy an export to clipboard.
13. Use the share sheet.

Pass criteria:

- No action traps the app in a disabled or loading state.
- Reopened saved takes do not imply live capture is still running.
- Export content matches the selected active or saved take.

## Failure And Recovery Pass

Run these on at least one platform before broader testing:

1. Launch with no model source configured.
2. Confirm setup explains the missing source and shows developer guidance.
3. Launch with a bad managed URL.
4. Confirm retry, local import, and diagnostics are available.
5. Launch with an invalid token for a gated URL.
6. Confirm token guidance appears without exposing token contents.
7. Deny camera permission.
8. Confirm permission recovery copy appears and the app does not crash.
9. Import an unsupported local file.
10. Confirm the prior source is preserved.

Pass criteria:

- Each failure produces a distinct action path.
- Reset, retry, local import, and managed-source recovery remain reachable.
- No private URL/token value is shown in normal user-facing text.

## Evidence To Record

For each tested device, record:

- Device model and OS version
- Git commit SHA
- Model source type: managed URL or imported local file
- Setup duration
- First-token time if visible in debug diagnostics
- Full-response time if visible in debug diagnostics
- Backend: GPU, CPU, or fallback
- Any thermal/performance problems after 5 minutes
- Screenshots of onboarding, setup success, director, Take Library, export, and Model Center

Use this result format:

```text
Device:
OS:
Commit:
Model source:
Setup result:
First screenplay result:
Relaunch reuse:
Local import:
Reset/source switch:
Export/share:
Backend/fallback:
Issues:
Pass/fail:
```
