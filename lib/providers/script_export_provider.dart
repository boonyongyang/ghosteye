import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/script_export_service.dart';

final scriptExportServiceProvider = Provider<ScriptExportService>((ref) {
  return ScriptExportService();
});
