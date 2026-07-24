# Flutter Upgrade Spike — 3.24.4 → 3.44.7

Exploratory spike to answer: **can Ghosteye move off the pinned Flutter 3.24.4
(Oct 2024) to current stable, and what does it cost?** This also unblocks the
dependency refresh (roadmap item 11) and is prerequisite work for the Gemma 4
spike. Kept on the isolated `flutter-upgrade-spike` branch per the roadmap
guardrail — **not** for mainline merge until on-device parity is proven.

## Recommendation: GO (conditional on device validation)

The upgrade is mechanically viable and small in code terms. The core risk —
`flutter_gemma` compatibility — is clear. Two changes plus one test fix get the
host suite green on 3.44.7. The only thing this environment cannot prove is
on-device Gemma inference on ARM, which still needs a physical device.

Target: **Flutter 3.44.7 / Dart 3.12.2** (latest stable at spike time; ~20 minor
versions and ~1.5 years ahead of the 3.24.4 pin).

## Gate results

| Gate | Result |
|---|---|
| `pub get` resolves | ✅ `flutter_gemma 0.11.8` still resolves; the `background_downloader` override holds; 36 transitive deps bump; the removed `macros`/`_macros` SDK packages drop |
| `flutter analyze` | ✅ **clean, no code migration needed** — the lib is already `withValues`-based (0 `withOpacity`), so the usual 3.24→3.44 color-API deprecation is already done |
| Compilation | ✅ after one dependency bump (see below) |
| `flutter test` | ⚠️ **280 / 281** — one onboarding widget-test fails on a hit-test behavior change (see below) |
| On-device runtime (ARM + real Gemma model) | ❓ **not validated** — out of scope for a hosted x64 environment; the real remaining risk |

## Required changes

### 1. Bump `google_fonts` (mandatory, and it makes the change atomic)

`google_fonts 6.3.0` (what `^6.2.1` resolves to) **fails to compile on Dart
3.12**: its `const` map keyed by `FontWeight` breaks because `FontWeight` is no
longer a primitive-`==` type in the newer `dart:ui`. Analyzer misses this
(lenient on const-eval); the compiler front-end does not — so `flutter analyze`
was green while three test files failed to load.

Fix: `google_fonts: ^6.2.1 → ^8.2.0`.

**This couples the two upgrades.** `google_fonts 8.x` requires Dart `^3.10.0`, so
it cannot resolve on Flutter 3.24.4 (Dart 3.5.4):

```
Because google_fonts 8.2.0 requires SDK version ^3.10.0 ...
So, because ghosteye depends on google_fonts ^8.2.0, version solving failed.
* Try using the Flutter SDK version: 3.44.8.
```

So the Flutter bump, the `google_fonts` bump, and the CI `flutter-version`
(`.github/workflows/verify.yml`) must all land **together**, in one change.

### 2. CI Flutter version

`.github/workflows/verify.yml`: `flutter-version: "3.24.4" → "3.44.7"`.
(Done on this branch — so this branch's CI cannot be evaluated against the old
pinned SDK; that's expected and correct.)

## Remaining work (the one open item)

`test/widgets/app_router_test.dart` → `skip also advances from onboarding to
setup` fails on 3.44.7: after `tester.tap(find.text('Skip'))`, the setup screen
never appears because the tap does not reach the button ("widget is off-screen,
obscured, or cannot receive pointer events"). The sibling `Start setup` test
passes. `tester.ensureVisible` before the tap did **not** fix it, so this is not
a simple scroll — it is a real Stack/overlay hit-test behavior change affecting
the onboarding top-bar `Skip` (`_GlassPillButton`, `lib/screens/onboarding_screen.dart`).

This is a bounded layout/interaction fix, not a build or ML blocker. It needs a
short look at the onboarding `Stack` on 3.44.7 (likely a decorative layer now
intercepting pointer events) — deferred as the concrete first task if the team
commits to the upgrade.

## What was NOT tested here

- On-device Gemma 3n inference on Android/iPhone under 3.44.7 (GPU/CPU, TFLite /
  MediaPipe stack via `flutter_gemma`). **This is the decisive remaining risk**
  and must be validated on hardware before merging to mainline.
- A native Android/iOS build (`flutter build apk/ios`) — only host `analyze` +
  `test` were run.

## Suggested path if the team proceeds

1. Land Flutter 3.44.7 + `google_fonts ^8.2.0` + CI version bump as one PR.
2. Fix the onboarding `Skip` hit-test (the single failing test).
3. Validate on-device Gemma inference on a physical Android device and iPhone.
4. Then fold in the wider dependency refresh (roadmap item 11), which this
   unblocks.
