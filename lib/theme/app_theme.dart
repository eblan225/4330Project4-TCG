import 'package:flutter/material.dart';

/// Central color palette for the animal-themed trading card game.
/// Keeping every color here means new screens automatically match
/// the rest of the app instead of picking their own colors.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF4ECD8); // parchment
  static const Color surface = Color(0xFFFFFBF2);
  static const Color forestGreen = Color(0xFF2E7D32);
  static const Color darkForestGreen = Color(0xFF1B4D20);
  static const Color earthBrown = Color(0xFF6D4C41);
  static const Color goldAccent = Color(0xFFC9A227);

  static const Color rarityCommon = Color(0xFF8D8D8D);
  static const Color rarityUncommon = Color(0xFF3E9B4F);
  static const Color rarityRare = Color(0xFF3B6FD6);
  static const Color rarityLegendary = Color(0xFFC9A227);
}

/// Builds the single app-wide theme. One shared light theme keeps
/// things simple for a class project; dark mode can be added later
/// if it's ever needed.
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.forestGreen),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkForestGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: AppColors.darkForestGreen,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: AppColors.darkForestGreen,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.darkForestGreen,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
