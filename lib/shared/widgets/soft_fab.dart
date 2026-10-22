import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Botón flotante en forma de píldora, con degradado suave y sombra
/// difuminada del mismo color. Se usa para "Agregar", "Nueva tarjeta",
/// "Nueva categoría", etc.
class SoftFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const SoftFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(AppColors.seed, Colors.white, 0.28)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, AppColors.seed],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
