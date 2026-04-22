# ghosteye_frame_ffi

`ghosteye_frame_ffi` is an internal Flutter FFI plugin used by Ghosteye to speed up camera-frame preprocessing before images are handed to the Gemma runtime.

It is a path dependency inside the main app repo, not a standalone package intended for `pub.dev`.

## What it does

- Converts `BGRA8888` camera frames into resized RGB buffers
- Converts `YUV420` camera frames into resized RGB buffers
- Exposes lightweight allocation tracking so the app tests can catch native-memory leaks
- Gives Ghosteye an optional preprocessing backend alongside the pure-Dart implementation

## Why it exists

The main Ghosteye app has a live camera-to-screenplay loop. This package isolates the native frame-conversion work so the app can compare a pure-Dart preprocessing path against an FFI-backed path without mixing that code directly into the main app package.

The real question for this package is not "can it compile?" but "does it materially improve first-token or end-to-end responsiveness on real hardware?" Treat it as an internal optimization surface until that device-level measurement is complete.

## Relevant files

- `lib/ghosteye_frame_ffi.dart`
  Dart API used by the app-side frame preprocessor
- `src/ghosteye_frame_ffi.h`
  Native function declarations
- `src/ghosteye_frame_ffi.c`
  Shared native implementation
- `ios/Classes/ghosteye_frame_ffi.c`
  iOS build entry point
- `macos/Classes/ghosteye_frame_ffi.c`
  macOS build entry point
- `ffigen.yaml`
  Binding-generation config

## Regenerating bindings

```bash
dart run ffigen --config ffigen.yaml
```

## Verifying from the app repo

Use the main Ghosteye verification flow from the repo root:

```bash
make verify
flutter test test/services/frame_preprocessor_test.dart
```

## Platform scope

This package currently targets the same platforms the app exercises for preprocessing experiments:

- Android
- iOS
- macOS
