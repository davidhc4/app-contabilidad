import 'package:flutter/material.dart';

import '../../core/utils/icon_map.dart';

class CategoryIcon extends StatelessWidget {
  final String icon;
  final String colorHex;
  final double size;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.colorHex,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(iconFor(icon), color: color, size: size * 0.52),
    );
  }
}
