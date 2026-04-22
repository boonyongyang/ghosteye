import 'package:flutter/material.dart';

import '../config/constants.dart';
import 'script_scroll_view.dart';

class TeleprompterOverlay extends StatelessWidget {
  const TeleprompterOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      heightFactor: AppConstants.teleprompterHeightFactor,
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withOpacity(0),
              Colors.black.withOpacity(0.64),
              Colors.black.withOpacity(0.88),
            ],
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(18, 36, 18, 18),
          child: ScriptScrollView(),
        ),
      ),
    );
  }
}
