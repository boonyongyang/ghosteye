import 'package:flutter_test/flutter_test.dart';
import 'package:ghosteye/providers/preferences_provider.dart';

enum _Pace { slow, steady, fast }

void main() {
  group('readPersistedEnum', () {
    test('resolves a stored name to its variant', () {
      expect(
        readPersistedEnum('steady', _Pace.values, _Pace.slow),
        equals(_Pace.steady),
      );
    });

    test('falls back when nothing is stored yet', () {
      // Fresh install: the key has never been written.
      expect(
        readPersistedEnum(null, _Pace.values, _Pace.steady),
        equals(_Pace.steady),
      );
    });

    test('falls back when the stored name no longer exists', () {
      // The real failure mode: a variant is renamed or removed in a later
      // release while an older value is still on disk. This must degrade to the
      // default rather than throw on startup.
      expect(
        readPersistedEnum('turbo', _Pace.values, _Pace.slow),
        equals(_Pace.slow),
      );
    });

    test('does not match on case or whitespace variants', () {
      for (final stored in <String>['Steady', 'STEADY', ' steady']) {
        expect(
          readPersistedEnum(stored, _Pace.values, _Pace.fast),
          equals(_Pace.fast),
          reason: '"$stored" is not a valid enum name',
        );
      }
    });

    test('falls back on an empty stored value', () {
      expect(
        readPersistedEnum('', _Pace.values, _Pace.fast),
        equals(_Pace.fast),
      );
    });
  });
}
