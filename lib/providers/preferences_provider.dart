import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The production app loads this once before `runApp`; tests can leave it
/// null and still get deterministic in-memory defaults.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

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
