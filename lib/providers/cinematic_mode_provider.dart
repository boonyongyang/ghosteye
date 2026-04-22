import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cinematic_mode.dart';

final cinematicModeProvider = StateProvider<CinematicMode>((ref) {
  return CinematicMode.noir;
});
