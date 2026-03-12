import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primaryRed,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryRed,
      surface: const Color(0xFF121212),
    ),
    textTheme: AppTypography.textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white, 
        fontSize: 18, 
        fontWeight: FontWeight.w600
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.textGrey,
      indicatorColor: AppColors.primaryRed,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    primaryColor: AppColors.primaryRed,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryRed,
      surface: AppColors.surfaceLight,
    ),
    textTheme: AppTypography.textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: AppColors.primaryRed.withValues(alpha: 0.05),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.textBlack,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 4,
      shadowColor: AppColors.primaryRed.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.textBlack, // Default for Light
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.primaryRed,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}