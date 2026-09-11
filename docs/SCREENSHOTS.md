# Screenshots

Rendered from the real widget tree — the actual screen widgets, the actual
`AppTheme`, and the app's real fonts — captured headlessly at a 390x844 phone
viewport.

Regenerate them with:

```bash
make screenshots
```

## What is real here, and what is not

These are **not** mockups. Each image is the production widget rendered by
Flutter. Two of them go further and exercise real app logic rather than
hand-built fixtures:

- **The teleprompter** was produced by streaming a scene through the real
  `ScriptController` token API (`startResponse` / `appendToken` /
  `finishResponse`). The slugline, action, character, parenthetical and
  dialogue styling you see is the app's own Fountain classifier deciding how to
  format each line.
- **The take library** card was not constructed by hand either. It is the take
  that the teleprompter run above produced, after it synced through
  `ScriptHistoryService` — which is why it reports its own line count.

What these images **cannot** show is the two things that need physical
hardware:

- **The live camera feed.** `DirectorCameraPreview` needs a real plugin
  `CameraController`, so the Director screen's camera layer is not captured.
- **Real Gemma 3n inference.** The screenplay text above is a fixed sample fed
  through the parser, *not* model output. On-device inference needs an ARM
  device and a real model file.

So: the UI, the theme, the typography, the screenplay formatting and the take
persistence are all genuine. The camera frame and the model's authorship are
not represented.

## Onboarding

The four-step first-run flow. The last step hands off to the setup workspace,
where the model source is chosen.

| Intro | Model source handoff |
|---|---|
| ![Onboarding intro](screenshots/01-onboarding-intro.png) | ![Onboarding model source handoff](screenshots/02-onboarding-handoff.png) |

## Teleprompter

The live screenplay surface. Everything below the slugline was classified by
the app's Fountain parser from a raw token stream.

![Teleprompter showing a parsed screenplay scene](screenshots/03-teleprompter.png)

## Take library and director tips

Recent takes persist locally with a mode tag and line count. The tips sheet is
what pauses the scene before the first capture.

| Take library | Director tips |
|---|---|
| ![Take library listing a saved take](screenshots/04-take-library.png) | ![Director tips sheet](screenshots/05-director-tips.png) |

## How the harness works

`tool/screenshots/generate_screenshots.dart` is a `flutter_test` file kept
outside `test/` so the CI suite never runs it — the same isolation the
`benchmark/` directory uses.

Three details are load-bearing, and all three were failure modes first:

1. **Fonts must be registered per test.** The theme's type comes from
   `google_fonts`, which cannot fetch in a headless test. The faces are fetched
   by `make screenshots` into a gitignored `.screenshot-fonts/` and registered
   with `FontLoader` under the exact variant names google_fonts asks for
   (`CourierPrime_regular`, `CourierPrime_700`, ...). This happens in `setUp`,
   not `setUpAll`, because the test binding resets registered fonts between
   test cases. Material's icon font is loaded from the Flutter SDK the same way,
   or every `Icon` draws as an empty box.
2. **The theme is built exactly once.** google_fonts throws when it cannot find
   its own copy of a font, and it *removes* the variant from its attempted-set
   on failure — so every rebuild throws again, as an unawaited future that
   `tester.takeException()` cannot reach. The theme is therefore constructed a
   single time inside a guarded zone and reused.
3. **Capture goes through `matchesGoldenFile`.** A manual
   `RenderRepaintBoundary.toImage()` writes a correct PNG but leaves the test
   shell unable to shut down, so the run hangs after the file lands.

Pumping is bounded rather than `pumpAndSettle()`, whose ten-minute default
timeout turns any never-settling animation into a ten-minute stall.
