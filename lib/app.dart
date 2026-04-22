import 'package:flutter/material.dart';

import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';

class GhostEyeApp extends StatelessWidget {
  const GhostEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
