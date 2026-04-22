import 'package:flutter/material.dart';

import '../config/constants.dart';

class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.targetText,
    this.charDelay = AppConstants.typewriterCharDelay,
    this.cursorBlinkInterval = AppConstants.cursorBlinkInterval,
  });

  final String targetText;
  final Duration charDelay;
  final Duration cursorBlinkInterval;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  Duration _lastCharacterStep = Duration.zero;
  Duration _lastCursorStep = Duration.zero;
  int _visibleCharacters = 0;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_handleTick)
      ..repeat(min: 0, max: 1, period: const Duration(milliseconds: 16));
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetText.length < oldWidget.targetText.length) {
      _visibleCharacters = 0;
      _lastCharacterStep = Duration.zero;
      _lastCursorStep = Duration.zero;
      _showCursor = true;
      return;
    }
    _visibleCharacters = _visibleCharacters.clamp(0, widget.targetText.length);
  }

  @override
  void dispose() {
    _ticker
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  void _handleTick() {
    final elapsed = _ticker.lastElapsedDuration ?? Duration.zero;

    if (_visibleCharacters < widget.targetText.length &&
        elapsed - _lastCharacterStep >= widget.charDelay) {
      setState(() {
        _visibleCharacters += 1;
        _lastCharacterStep = elapsed;
        _showCursor = true;
      });
      return;
    }

    if (_visibleCharacters >= widget.targetText.length &&
        elapsed - _lastCursorStep >= widget.cursorBlinkInterval) {
      setState(() {
        _showCursor = !_showCursor;
        _lastCursorStep = elapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.targetText.substring(0, _visibleCharacters);
    final cursorColor = Theme.of(context).colorScheme.primary;

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: <InlineSpan>[
          TextSpan(text: visibleText),
          TextSpan(
            text: _showCursor ? '|' : ' ',
            style: TextStyle(color: cursorColor),
          ),
        ],
      ),
    );
  }
}
