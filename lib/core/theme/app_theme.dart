import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tema de la app, estilo iOS: superficies oscuras neutras,
/// acentos vivos, tarjetas redondeadas, tipografía Inter.
class AppColors {
  AppColors._();

  static const seed = Color(0xFF0A84FF); // azul iOS
  static const income = Color(0xFF30D158); // verde iOS
  static const expense = Color(0xFFFF453A); // rojo iOS
  static const warning = Color(0xFFFF9F0A);

  // Dark
  static const darkBg = Color(0xFF0B0B0D);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkSurfaceElevated = Color(0xFF2C2C2E);
  static const darkBorder = Color(0xFF38383A);

  // Light
  static const lightBg = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF8F8FA);
  static const lightBorder = Color(0xFFE5E5EA);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
    );
    return _apply(base, isDark: true);
  }

  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
    );
    return _apply(base, isDark: false);
  }

  static ThemeData _apply(ThemeData base, {required bool isDark}) {
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: base.textTheme.bodyLarge?.color,
      displayColor: base.textTheme.displayLarge?.color,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.seed.withValues(alpha: 0.18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.seed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
