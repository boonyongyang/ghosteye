// Renders real Ghosteye screens headlessly and writes them to PNG files.
//
// This is a documentation tool, not a test. It lives outside `test/` so the
// CI suite (`flutter test`) never picks it up, the same way `benchmark/` is
// kept out of the suite.
//
// Run it with `make screenshots`. The brand faces are bundled in
// `assets/fonts`, but `flutter test` does not load an app's declared fonts
// automatically, so the harness registers them itself; otherwise the headless
// engine falls back to its test font and every glyph renders as a filled box.
//
// What these images are: the real widget tree, the real `AppTheme`, and — for
// the teleprompter — the real Fountain parser, driven through the real
// `ScriptController` token API. What they are not: a live camera feed or real
// Gemma inference. Both need physical hardware, so no screen that depends on
// them is captured here.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/theme.dart';
import 'package:ghosteye/models/onboarding_status.dart';
import 'package:ghosteye/providers/onboarding_provider.dart';
import 'package:ghosteye/providers/script_provider.dart';
import 'package:ghosteye/screens/onboarding_screen.dart';
import 'package:ghosteye/widgets/director_tips_sheet.dart';
import 'package:ghosteye/widgets/script_history_sheet.dart';
import 'package:ghosteye/widgets/script_scroll_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical size of a modern phone viewport.
const Size _viewport = Size(390, 844);

/// Rendered at 2x so the PNGs stay legible in docs without being enormous.
const double _scale = 2.0;

String get _outDir =>
    Platform.environment['GHOSTEYE_SCREENSHOT_OUT'] ?? 'docs/screenshots';

/// The brand faces are bundled in `assets/fonts` and declared in pubspec, but
/// `flutter test` does not load an app's declared fonts automatically — without
/// this every glyph renders as a filled box. Material's icon font ships with
/// the SDK rather than the app and needs the same treatment, or every `Icon`
/// draws as an empty square.
///
/// This must run in `setUp`, not `setUpAll`: the test binding resets registered
/// fonts between test cases, so loading once would only serve the first
/// screenshot.
const Map<String, List<String>> _bundledFonts = <String, List<String>>{
  'CourierPrime': <String>[
    'assets/fonts/CourierPrime-Regular.ttf',
    'assets/fonts/CourierPrime-Italic.ttf',
    'assets/fonts/CourierPrime-Bold.ttf',
    'assets/fonts/CourierPrime-BoldItalic.ttf',
  ],
  'CormorantGaramond': <String>['assets/fonts/CormorantGaramond.ttf'],
};

String? _materialIconsPath() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return null;
  }
  final sdkCopy = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  return sdkCopy.existsSync() ? sdkCopy.path : null;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Missing bundled font ${file.path}');
    }
    final bytes = file.readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _registerFonts() async {
  for (final entry in _bundledFonts.entries) {
    await _loadFont(entry.key, entry.value);
  }
  final icons = _materialIconsPath();
  if (icons != null) {
    await _loadFont('MaterialIcons', <String>[icons]);
  }
}

Widget _app(Widget home, {List<Override> overrides = const <Override>[]}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home,
    ),
  );
}

/// Wraps [child] so a sheet is shot on the app background rather than on the
/// transparent void it would otherwise sit in.
Widget _sheetHost(Widget child) {
  return Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: SingleChildScrollView(child: child)),
  );
}

/// Advances past the page-turn / fade animations without `pumpAndSettle`,
/// whose ten-minute default timeout turns any never-settling animation into a
/// ten-minute stall.
Future<void> _rest(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump();
}

Future<void> _shoot(
  WidgetTester tester,
  String name, {
  required Widget widget,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  final key = GlobalKey();

  tester.view.devicePixelRatio = _scale;
  tester.view.physicalSize = _viewport * _scale;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(RepaintBoundary(key: key, child: widget));
  await _rest(tester);
  if (afterPump != null) {
    await afterPump(tester);
  }

  // Written through the framework's golden pipeline rather than a manual
  // RenderRepaintBoundary.toImage(): the manual route rasterizes fine but
  // leaves the test shell unable to shut down, so the process hangs after the
  // file lands. Paths are relative to this file's directory.
  await expectLater(
    find.byKey(key),
    matchesGoldenFile('../../$_outDir/$name.png'),
  );
}

/// A short scene, streamed through the real token API so the checked-in image
/// shows genuine `ScriptController` Fountain classification rather than
/// hand-built entries.
const String _scene = '''
INT. RAIN-STREAKED APARTMENT - NIGHT

A bare bulb sways over a desk buried in unopened mail.

VOSS
(not looking up)
You kept every letter she sent.

MARLOW
I kept the ones that mattered.
''';

void main() {
  setUp(() async {
    // This file is a flutter_test harness; it just lives outside test/ so the
    // CI suite does not run it.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _registerFonts();
    Directory(_outDir).createSync(recursive: true);
  });

  testWidgets('onboarding — intro', (tester) async {
    await _shoot(
      tester,
      '01-onboarding-intro',
      widget: _app(
        const OnboardingScreen(),
        overrides: <Override>[
          onboardingProvider.overrideWith(_FreshOnboarding.new),
        ],
      ),
    );
  });

  testWidgets('onboarding — model source handoff', (tester) async {
    await _shoot(
      tester,
      '02-onboarding-handoff',
      widget: _app(
        const OnboardingScreen(),
        overrides: <Override>[
          onboardingProvider.overrideWith(_FreshOnboarding.new),
        ],
      ),
      afterPump: (tester) async {
        // Walk to the final page through the real PageView controls.
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.widgetWithText(FilledButton, 'Next'));
          await _rest(tester);
        }
      },
    );
  });

  testWidgets('teleprompter — parsed screenplay', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Drive the real streaming API so the real parser produces the entries.
    final script = container.read(scriptProvider.notifier)..startResponse(1);
    for (final token in _scene.split(' ')) {
      script.appendToken(generationId: 1, token: '$token ');
    }
    script.finishResponse(1);
    // finishResponse kicks off an unawaited SharedPreferences history sync;
    // let it settle or the test never finalizes.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    await _shoot(
      tester,
      '03-teleprompter',
      widget: UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(child: ScriptScrollView()),
          ),
        ),
      ),
    );
  });

  testWidgets('take library', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final script = container.read(scriptProvider.notifier)..startResponse(1);
    for (final token in _scene.split(' ')) {
      script.appendToken(generationId: 1, token: '$token ');
    }
    script.finishResponse(1);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    await _shoot(
      tester,
      '04-take-library',
      widget: UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: _sheetHost(
            ScriptHistorySheet(
              onSelectSession: (_) async {},
              onExportSession: (_) async {},
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('director tips', (tester) async {
    await _shoot(
      tester,
      '05-director-tips',
      widget: _app(
        _sheetHost(
          DirectorTipsSheet(
            primaryLabel: 'Start directing',
            onPrimaryPressed: () {},
          ),
        ),
      ),
    );
  });
}

class _FreshOnboarding extends OnboardingController {
  @override
  Future<OnboardingStatus> build() async => const OnboardingStatus.initial();

  @override
  Future<void> completeIntro() async {}

  @override
  Future<void> markDirectorTipsSeen() async {}
}
