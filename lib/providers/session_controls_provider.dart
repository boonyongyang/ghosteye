import 'package:flutter_riverpod/flutter_riverpod.dart';

final captureEnabledProvider = StateProvider<bool>((ref) {
  return true;
});

final reviewModeProvider = StateProvider<bool>((ref) {
  return false;
});
