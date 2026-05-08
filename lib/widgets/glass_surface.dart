import 'dart:ui';

import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 24.0,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.black.withOpacity(0.18);
    final border = borderColor ?? Colors.white12;

    Widget content =
        padding != null ? Padding(padding: padding!, child: child) : child;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border: Border.all(color: border),
          ),
          child: content,
        ),
      ),
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.blur = 18.0,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final Widget child;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  static const _radius = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: _radius,
      blur: blur,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: padding,
      child: child,
    );
  }
}
