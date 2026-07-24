# Flutter Upgrade Spike — 3.24.4 → 3.44.7

Exploratory spike to answer: **can Ghosteye move off the pinned Flutter 3.24.4
(Oct 2024) to current stable, and what does it cost?** This also unblocks the
dependency refresh (roadmap item 11) and is prerequisite work for the Gemma 4
spike. Kept on the isolated `flutter-upgrade-spike` branch per the roadmap
guardrail — **not** for mainline merge until on-device parity is proven.

## Recommendation: GO (conditional on device validation)

The upgrade is mechanically viable and small in code terms. The core risk —
`flutter_gemma` compatibility — is clear. One dependency bump plus one
test-only fix get the **full host suite green (281/281)** on 3.44.7. The only
thing this environment cannot prove is on-device Gemma inference on ARM, which
still needs a physical device.

Target: **Flutter 3.44.7 / Dart 3.12.2** (latest stable at spike time; ~20 minor
versions and ~1.5 years ahead of the 3.24.4 pin).

## Gate results

| Gate | Result |
|---|---|
| `pub get` resolves | ✅ `flutter_gemma 0.11.8` still resolves; the `background_downloader` override holds; 36 transitive deps bump; the removed `macros`/`_macros` SDK packages drop |
| `flutter analyze` | ✅ **clean, no code migration needed** — the lib is already `withValues`-based (0 `withOpacity`), so the usual 3.24→3.44 color-API deprecation is already done |
| Compilation | ✅ after one dependency bump (see below) |
| `flutter test` | ✅ **281 / 281** — after one test-only timing fix (see below) |
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

## The one test failure — root cause and fix (resolved)

`test/widgets/app_router_test.dart` → `skip also advances from onboarding to
setup` failed on 3.44.7. It looked like a hit-test/overlay regression, but the
tap warning gave it away:

```
Offset(941.8, 40.0) is outside the bounds of the root of the render tree, Size(800.0, 600.0)
```

The `Skip` pill sits at **x≈941.8 on an 800px-wide surface** — off the right
edge — because the onboarding screen is still **mid-slide in its route-entry
transition** when the test taps. It is not an overlay, not a decorative layer,
and **not** a production layout bug (the top-bar `Skip` renders fine on real,
narrower devices). The sibling `Start setup` test survives only because it calls
`pumpAndSettle()` between the onboarding pages, which settles that same entry
transition; the skip test used bare `pump()`s and tapped while the page was
still animating. On 3.44.7 the entry transition simply runs longer than the
~400 ms the test pumps.

Fix (test-only): settle the onboarding entry transition before tapping —

```dart
await tester.pumpAndSettle(); // onboarding has no infinite animation here
await tester.tap(find.text('Skip'));
```

This is safe on both toolchains: on 3.24.4 the transition is already settled, so
`pumpAndSettle()` is a no-op; and it does **not** risk hanging, because the only
infinite animation (the setup progress spinner) lives one route later, which
this test never reaches. No production code changed.

## What was NOT tested here

- On-device Gemma 3n inference on Android/iPhone under 3.44.7 (GPU/CPU, TFLite /
  MediaPipe stack via `flutter_gemma`). **This is the decisive remaining risk**
  and must be validated on hardware before merging to mainline.
- A native Android/iOS build (`flutter build apk/ios`) — only host `analyze` +
  `test` were run.

## Suggested path if the team proceeds

1. Land Flutter 3.44.7 + `google_fonts ^8.2.0` + CI version bump + the
   `app_router_test` settle fix as one PR (all four already staged on this
   branch; host suite is 281/281).
2. Validate on-device Gemma inference on a physical Android device and iPhone.
3. Then fold in the wider dependency refresh (roadmap item 11), which this
   unblocks.
