import 'package:flutter/material.dart';

import 'christmas_overlay.dart';

/// Capa que va encima de toda la app para las decoraciones de temporada
/// (hoy, el tema de Navidad).
class ThemeFxLayer extends StatelessWidget {
  final Widget child;
  const ThemeFxLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        child,
        const ChristmasFx(),
      ],
    );
  }
}
