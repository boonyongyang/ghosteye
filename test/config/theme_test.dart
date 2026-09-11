import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/config/theme.dart';

/// Families the app ships. These are asserted against both the theme and
/// pubspec so a rename on either side fails loudly instead of silently
/// dropping the brand type back to a platform default.
const _monoFamily = 'CourierPrime';
const _displayFamily = 'CormorantGaramond';

String _pubspec() => File('pubspec.yaml').readAsStringSync();

/// Every `- asset: assets/fonts/...` entry declared in pubspec.
List<String> _declaredFontAssets() {
  return RegExp(
    r'-\s*asset:\s*(assets/fonts/[^\s]+)',
  ).allMatches(_pubspec()).map((m) => m.group(1)!).toList();
}

void main() {
  group('AppTheme typography', () {
    test('body and title styles use the bundled monospace family', () {
      final textTheme = AppTheme.darkTheme.textTheme;

      for (final style in <TextStyle?>[
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
      ]) {
        expect(style, isNotNull);
        expect(style!.fontFamily, equals(_monoFamily));
      }
    });

    test('displaySmall uses the bundled display family at bold weight', () {
      final displaySmall = AppTheme.darkTheme.textTheme.displaySmall;

      expect(displaySmall, isNotNull);
      expect(displaySmall!.fontFamily, equals(_displayFamily));
      expect(displaySmall.fontWeight, equals(FontWeight.w700));
    });

    test('displaySmall selects its weight through the variable-font axis', () {
      // Cormorant Garamond ships upstream as a single variable face, so
      // fontWeight alone does not pick a bold cut -- the wght axis has to be
      // set explicitly or the title silently renders at regular weight.
      final displaySmall = AppTheme.darkTheme.textTheme.displaySmall;

      expect(
        displaySmall!.fontVariations,
        contains(const FontVariation('wght', 700)),
      );
    });

    test('no text style falls back to a generic platform family', () {
      // Guards the regression this replaced: 'monospace'/'serif' render as
      // whatever the platform supplies, which loses the brand type.
      final textTheme = AppTheme.darkTheme.textTheme;
      final families = <String?>[
        textTheme.displayLarge?.fontFamily,
        textTheme.displayMedium?.fontFamily,
        textTheme.displaySmall?.fontFamily,
        textTheme.headlineLarge?.fontFamily,
        textTheme.headlineMedium?.fontFamily,
        textTheme.headlineSmall?.fontFamily,
        textTheme.titleLarge?.fontFamily,
        textTheme.titleMedium?.fontFamily,
        textTheme.titleSmall?.fontFamily,
        textTheme.bodyLarge?.fontFamily,
        textTheme.bodyMedium?.fontFamily,
        textTheme.bodySmall?.fontFamily,
        textTheme.labelLarge?.fontFamily,
        textTheme.labelMedium?.fontFamily,
        textTheme.labelSmall?.fontFamily,
      ];

      for (final family in families) {
        expect(family, isNotNull);
        expect(
          family,
          anyOf(equals(_monoFamily), equals(_displayFamily)),
          reason: '$family is not a bundled Ghosteye family',
        );
      }
    });
  });

  group('bundled font assets', () {
    test('pubspec declares both families the theme asks for', () {
      final pubspec = _pubspec();

      expect(pubspec, contains('family: $_monoFamily'));
      expect(pubspec, contains('family: $_displayFamily'));
    });

    test('every declared font file exists on disk', () {
      final declared = _declaredFontAssets();

      expect(
        declared,
        isNotEmpty,
        reason: 'pubspec should declare the bundled font assets',
      );

      for (final asset in declared) {
        expect(
          File(asset).existsSync(),
          isTrue,
          reason: '$asset is declared in pubspec but missing from the repo',
        );
      }
    });

    test('the mono family ships regular, bold, and both italics', () {
      final declared = _declaredFontAssets().join('\n');

      expect(declared, contains('$_monoFamily-Regular.ttf'));
      expect(declared, contains('$_monoFamily-Bold.ttf'));
      expect(declared, contains('$_monoFamily-Italic.ttf'));
      expect(declared, contains('$_monoFamily-BoldItalic.ttf'));
    });

    test('each bundled family keeps its license beside it', () {
      // Both families are SIL OFL; redistribution requires the license.
      expect(File('assets/fonts/$_monoFamily-OFL.txt').existsSync(), isTrue);
      expect(File('assets/fonts/$_displayFamily-OFL.txt').existsSync(), isTrue);
    });

    test('no runtime font fetching dependency is declared', () {
      // The app must render its own type offline: frames never leave the
      // device, and a first run without network would otherwise fall back to
      // platform defaults.
      expect(
        _pubspec().contains('google_fonts'),
        isFalse,
        reason: 'fonts are bundled; google_fonts must not come back',
      );
    });
  });
}
