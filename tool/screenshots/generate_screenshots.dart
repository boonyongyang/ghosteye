// Renders real Ghosteye screens headlessly and writes them to PNG files.
//
// This is a documentation tool, not a test. It lives outside `test/` so the
// CI suite (`flutter test`) never picks it up, the same way `benchmark/` is
// kept out of the suite.
//
// Run it with `make screenshots`, which downloads the two Google Fonts
// families the theme uses into a gitignored directory first. Without those
// fonts the headless engine falls back to its test font and every glyph
// renders as a filled box.
//
// What these images are: the real widget tree, the real `AppTheme`, and — for
// the teleprompter — the real Fountain parser, driven through the real
// `ScriptController` token API. What they are not: a live camera feed or real
// Gemma inference. Both need physical hardware, so no screen that depends on
// them is captured here.

import 'dart:async';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical size of a modern phone viewport.
const Size _viewport = Size(390, 844);

/// Rendered at 2x so the PNGs stay legible in docs without being enormous.
const double _scale = 2.0;

String get _fontsDir =>
    Platform.environment['GHOSTEYE_SCREENSHOT_FONTS'] ?? '.screenshot-fonts';

String get _outDir =>
    Platform.environment['GHOSTEYE_SCREENSHOT_OUT'] ?? 'docs/screenshots';

/// google_fonts builds a `TextStyle` whose primary `fontFamily` is
/// `'<Family>_<variant>'`, where variant is `regular`, `italic`, `700`,
/// `700italic`, and so on (see `GoogleFontsVariant.toString`). Registering only
/// the bare family name and leaning on `fontFamilyFallback` is not enough in
/// the headless engine — it keeps the Ahem test font and every glyph renders as
/// a filled box. So every variant name is registered explicitly.
///
/// These must be registered in `setUp`, not `setUpAll`: the test binding resets
/// registered fonts between test cases, so fonts loaded once would only survive
/// into the first screenshot.
final Map<String, Uint8List> _fontCache = <String, Uint8List>{};

Uint8List _fontBytes(String fileName) {
  return _fontCache.putIfAbsent(fileName, () {
    final file = File('$_fontsDir/$fileName');
    if (!file.existsSync()) {
      throw StateError(
        'Missing font ${file.path}. Run `make screenshots`, which fetches the '
        'fonts before invoking this tool.',
      );
    }
    return file.readAsBytesSync();
  });
}

/// Maps every google_fonts variant name to the face that should satisfy it.
Map<String, String> _fontRegistrations() {
  final map = <String, String>{
    'CourierPrime': 'CourierPrime-Regular.ttf',
    'CormorantGaramond': 'CormorantGaramond-var.ttf',
  };

  for (var weight = 100; weight <= 900; weight += 100) {
    // w400 stringifies to 'regular'/'italic'; every other weight keeps its number.
    final upright = weight == 400 ? 'regular' : '$weight';
    final italic = weight == 400 ? 'italic' : '${weight}italic';
    final bold = weight >= 600;

    map['CourierPrime_$upright'] =
        bold ? 'CourierPrime-Bold.ttf' : 'CourierPrime-Regular.ttf';
    map['CourierPrime_$italic'] =
        bold ? 'CourierPrime-BoldItalic.ttf' : 'CourierPrime-Italic.ttf';
    // Cormorant Garamond ships as a single variable face upstream.
    map['CormorantGaramond_$upright'] = 'CormorantGaramond-var.ttf';
    map['CormorantGaramond_$italic'] = 'CormorantGaramond-var.ttf';
  }

  return map;
}

/// Material's icon glyphs live in a font that ships with the Flutter SDK
/// rather than in the app, so the headless engine draws every `Icon` as an
/// empty box until it is registered.
String? _materialIconsPath() {
  final vendored = File('$_fontsDir/MaterialIcons-Regular.otf');
  if (vendored.existsSync()) {
    return vendored.path;
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final sdkCopy = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (sdkCopy.existsSync()) {
      return sdkCopy.path;
    }
  }
  return null;
}

Future<void> _registerFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  final iconsPath = _materialIconsPath();
  if (iconsPath != null) {
    final iconBytes = File(iconsPath).readAsBytesSync();
    await (FontLoader('MaterialIcons')
          ..addFont(Future<ByteData>.value(ByteData.view(iconBytes.buffer))))
        .load();
  }

  for (final entry in _fontRegistrations().entries) {
    final bytes = _fontBytes(entry.value);
    await (FontLoader(entry.key)
          ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer))))
        .load();
  }
}

ThemeData? _cachedTheme;

/// The app theme, built exactly once.
///
/// google_fonts asks its own loader for every variant the theme constructs.
/// We deliberately do not ship these fonts as app assets and keep runtime
/// fetching off (determinism), so that lookup fails and throws — as an
/// unawaited future, which surfaces as a post-test failure that
/// `tester.takeException()` cannot reach. Worse, google_fonts *removes* a
/// variant from its attempted-set when the load fails, so every rebuild of the
/// theme throws again.
///
/// So build the theme a single time inside a guarded zone, swallow that one
/// round of errors, and hand the same [ThemeData] to every screenshot. The
/// glyphs come from the faces registered in [_registerFonts], so the rendered
/// type is correct regardless.
ThemeData _theme() {
  final cached = _cachedTheme;
  if (cached != null) {
    return cached;
  }

  late ThemeData built;
  // Synchronous on purpose: an `await` here would sit in flutter_test's fake
  // time inside a test body and never resolve. Building the theme is sync; the
  // google_fonts failures arrive later on futures created inside this zone, so
  // the zone's error handler still catches them.
  runZonedGuarded(
    () {
      built = AppTheme.darkTheme;
    },
    (Object error, StackTrace stack) {
      // Expected: "font X was not found in the application assets".
    },
  );

  _cachedTheme = built;
  return built;
}

Widget _app(
  ThemeData theme,
  Widget home, {
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
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

  // google_fonts is configured not to fetch at runtime, so it raises
  // "font X was not found in the application assets" for each variant. That is
  // expected here: the glyphs come from the faces registered in setUp, not from
  // google_fonts' own loader. Let those futures resolve, then drain them so
  // they do not surface as post-test failures.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  while (tester.takeException() != null) {
    // Discard; see comment above.
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
        _theme(),
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
        _theme(),
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
    final theme = _theme();
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
          theme: theme,
          home: const Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(child: ScriptScrollView()),
          ),
        ),
      ),
    );
  });

  testWidgets('take library', (tester) async {
    final theme = _theme();
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
          theme: theme,
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
        _theme(),
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
