import 'package:flutter/material.dart';

import 'package:ghosteye_frame_ffi/ghosteye_frame_ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GhosteyeFrameFfi? ffi;
  late final bool isSupported;

  @override
  void initState() {
    super.initState();
    isSupported = GhosteyeFrameFfi.isSupported;
    if (isSupported) {
      ffi = GhosteyeFrameFfi();
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This package exposes Ghosteye frame-preprocessing primitives through FFI. '
                  'The app uses it from a background isolate while keeping JPEG encoding on the Dart side.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'Supported on this platform: $isSupported',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'Active native allocations: ${ffi?.activeAllocationCount ?? 'n/a'}',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
