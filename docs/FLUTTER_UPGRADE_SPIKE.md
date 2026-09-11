# Flutter Upgrade Spike — 3.24.4 → 3.44.7

> **Superseded (2026-09-11).** Mainline moved to **Flutter 3.38.9 / Dart
> 3.10.8** as part of the Gemma 4 E2B runtime work, not to 3.44.7. This report
> is kept as the record of how the upgrade cost was measured — the atomicity
> finding and the onboarding route-entry diagnosis both still hold. The
> `flutter-upgrade-spike` branch is no longer a live plan and should not be
> merged.

Exploratory spike to answer: **can Ghosteye move off the pinned Flutter 3.24.4
(Oct 2024) to current stable, and what does it cost?** This also unblocks the
dependency refresh (roadmap item 11) and is prerequisite work for the Gemma 4
spike.

This file is the **decision record** and is kept on mainline so the finding is
not stranded. The **upgrade itself lives on the isolated `flutter-upgrade-spike`
branch** and is **not** for mainline merge until on-device parity is proven, per
the roadmap guardrail. Nothing in this document changes the pinned mainline
toolchain.

## Recommendation: GO (conditional on device validation)

The upgrade is mechanically viable, and the code change is wide but shallow. The
core risk — `flutter_gemma` compatibility — is clear. Three changes (a mechanical
49-call-site color-API migration, one dependency bump, the CI version) plus one
test-only fix get the **full host suite green (286/286)** on 3.44.7. The only
thing this environment cannot prove is on-device Gemma inference on ARM, which
still needs a physical device.

**All three changes are mutually atomic** — none of them can land on 3.24.4
(see each section below). This is a single-PR upgrade or nothing. The only
separable piece is the test fix, which is verified green on both SDKs.

Target: **Flutter 3.44.7 / Dart 3.12.2** (latest stable at spike time; ~20 minor
versions and ~1.5 years ahead of the 3.24.4 pin).

## Gate results

| Gate | Result |
|---|---|
| `pub get` resolves | ✅ `flutter_gemma 0.11.8` still resolves; the `background_downloader` override holds; 36 transitive deps bump; the removed `macros`/`_macros` SDK packages drop |
| `flutter analyze` | ✅ **clean — after** the `withOpacity` → `withValues` migration (49 call sites / 13 files). Without it, analyze reports the deprecated color API throughout `lib/` |
| Compilation | ✅ after one dependency bump (see below) |
| `flutter test` | ✅ **286 / 286** — after one test-only timing fix (see below) |
| On-device runtime (ARM + real Gemma model) | ❓ **not validated** — out of scope for a hosted x64 environment; the real remaining risk |

## Required changes

### 1. Migrate `withOpacity` → `withValues` (49 call sites, 13 files)

`Color.withOpacity(x)` has been deprecated since Flutter 3.27 and must become
`withValues(alpha: x)`. Mainline (3.24.4) uses `withOpacity` in **49 places
across 13 files** in `lib/` — `onboarding_screen.dart` (20) and
`director_screen.dart` (6) are the densest. Because `onboarding_screen.dart` is
both the densest file in this diff and was the least covered, it has since been
given dedicated widget coverage
(`test/widgets/onboarding_screen_test.dart`, green on **both** 3.24.4 and
3.44.7) so the migration has a behavioral safety net.

The migration is purely mechanical (a 49-insertion / 49-deletion diff, done here
in commit `131fbd1`) and carries no behavior change — `withValues(alpha:)` is
the direct replacement, and it avoids the precision loss `withOpacity` had.

**This is also atomic with the Flutter bump, in the opposite direction from
`google_fonts`:** `withValues` does **not exist** in the 3.24.4 SDK, so the
migrated code cannot compile on mainline. It must land *with* the upgrade — it
cannot be staged ahead of it as a warm-up PR.

### 2. Bump `google_fonts` (mandatory, and it makes the change atomic)

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

So the Flutter bump, the `google_fonts` bump, the color-API migration, and the
CI `flutter-version` (`.github/workflows/verify.yml`) must all land
**together**, in one change.

### 3. CI Flutter version

`.github/workflows/verify.yml`: `flutter-version: "3.24.4" → "3.44.7"`.
(Done on `flutter-upgrade-spike` — so that branch's CI cannot be evaluated
against the old pinned SDK; that's expected and correct.)

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

It does **not** risk hanging, because the only infinite animation (the setup
progress spinner) lives one route later, which this test never reaches. No
production code changed.

**Verified on both toolchains.** This was checked empirically, not assumed: the
patch was applied to a clean `origin/main` worktree and run on the mainline
3.24.4 SDK — `app_router_test` passes 4/4 there as well (on 3.24.4 the
transition has already settled by the time the test taps, so `pumpAndSettle()`
is effectively a no-op).

That makes this fix the **one piece of the upgrade that is *not* atomic** — it
is test-only, uses no new API, and is green on both SDKs, so it can be landed on
mainline *ahead* of the upgrade as a small de-risking PR if the team wants to
shrink the eventual upgrade diff.

## What was NOT tested here

- On-device Gemma 3n inference on Android/iPhone under 3.44.7 (GPU/CPU, TFLite /
  MediaPipe stack via `flutter_gemma`). **This is the decisive remaining risk**
  and must be validated on hardware before merging to mainline.
- A native Android/iOS build (`flutter build apk/ios`) — only host `analyze` +
  `test` were run.

## Suggested path if the team proceeds

1. Land it as one PR — Flutter 3.44.7 + the `withOpacity`→`withValues`
   migration + `google_fonts ^8.2.0` + CI version bump + the `app_router_test`
   settle fix. All five are already staged on `flutter-upgrade-spike` and the
   host suite is 286/286 there, so that branch *is* the upgrade PR content.
2. Validate on-device Gemma inference on a physical Android device and iPhone.
3. Then fold in the wider dependency refresh (roadmap item 11), which this
   unblocks.
