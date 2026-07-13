import 'package:flutter/material.dart';
import 'package:islami/core/theme/app_colors.dart';

abstract class ThemeManager {
  // NOTE: this is the app's single (dark) theme — named `darkTheme` after the
  // Figma file, which ships one dark theme only.
  static ThemeData darkTheme() => ThemeData(
    // Janna at the theme level so no widget can fall back to Arial (spec §3,
    // Figma review comment #6). Ad-hoc TextStyles without a family inherit this.
    fontFamily: 'Janna',
    scaffoldBackgroundColor: AppColors.backgroundColor,
    primaryColor: AppColors.primaryColor,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      // The label sits UNDER the pill, on the gold bar -> dark, not white.
      // (The white is only for the icon INSIDE the dark pill.) spec §2.9.
      selectedItemColor: AppColors.titleTextColor,
      unselectedItemColor: AppColors.titleTextColor,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Janna',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.titleTextColor,
      ),
    ),
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontFamily: "Janna",
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.backgroundColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: "Janna",
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.backgroundColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: "Janna",
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.backgroundColor,
      ),
      titleLarge: TextStyle(
        fontFamily: "Janna",
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.backgroundColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: "Janna",
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.backgroundColor,
      )
    ),
  );
}