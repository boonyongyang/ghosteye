import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app-wide [SharedPreferences] instance, preloaded in `main()` and
/// supplied via a `ProviderScope` override.
///
/// The default is `null`, which means persistence is unavailable and providers
/// fall back to their in-memory defaults. This keeps unit/widget tests that do
/// not care about persistence free of any override, while production and
/// persistence-focused tests supply a real instance.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Resolves a persisted enum by its `name`, falling back when the stored value
/// is absent or no longer maps to a known variant (e.g. after a rename).
T readPersistedEnum<T extends Enum>(
  String? storedName,
  List<T> values,
  T fallback,
) {
  if (storedName == null) {
    return fallback;
  }
  for (final value in values) {
    if (value.name == storedName) {
      return value;
    }
  }
  return fallback;
}
