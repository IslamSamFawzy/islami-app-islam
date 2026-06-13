import 'package:flutter/material.dart';
import 'package:islami/core/theme/app_colors.dart';

abstract class ThemeManager {
  static ThemeData lightTheme() => ThemeData(
    scaffoldBackgroundColor: AppColors.backgroundColor,
    primaryColor: AppColors.primaryColor,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primaryColor,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      selectedItemColor: Colors.white,
      selectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
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