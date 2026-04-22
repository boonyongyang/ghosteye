import 'package:flutter/material.dart';

import '../config/constants.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 136,
    this.radius = 32,
  });

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x5500C9FF),
            blurRadius: 32,
            spreadRadius: -8,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          AppConstants.brandAssetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF10212C),
                    Color(0xFF0A0D12),
                  ],
                ),
                border: Border.all(color: const Color(0x22F2B95C)),
              ),
              child: const Center(
                child: Icon(
                  Icons.visibility_rounded,
                  size: 54,
                  color: Color(0xFFF2B95C),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
