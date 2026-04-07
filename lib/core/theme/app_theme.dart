import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs - Thème bleu-clair modernisé
  static const Color darkBg = Color(0xFFF0F4F8);          // Blanc-bleu très clair
  static const Color darkBgLight = Color(0xFFFFFFFF);     // Blanc pur
  static const Color darkBgLighter = Color(0xFFE8F1F8);   // Très clair bleu
  static const Color accentBlue = Color(0xFF0066CC);       // Bleu électrique
  static const Color accentCyan = Color(0xFF0099FF);       // Bleu ciel
  static const Color accentGreen = Color(0xFF10B981);      // Vert clair
  static const Color textPrimary = Color(0xFF1A202C);      // Bleu-noir foncé
  static const Color textSecondary = Color(0xFF718096);    // Gris-bleu modéré

  // Couleurs activities
  static const Color activityGreen = Color(0xFF10B981);
  static const Color activityOrange = Color(0xFFF59E0B);
  static const Color activityRed = Color(0xFFEF4444);

// ThemeData
static ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: darkBg,
  primaryColor: accentBlue,
  colorScheme: ColorScheme.light(
    primary: accentBlue,
    secondary: accentCyan,
    surface: darkBgLight,
    surfaceContainerHighest: darkBgLighter,
    error: activityRed,
  ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBgLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: accentBlue),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkBgLight,
      indicatorColor: accentBlue.withOpacity(0.1),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: accentBlue);
        }
        return const IconThemeData(color: textSecondary);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(color: accentBlue);
        }
        return const TextStyle(color: textSecondary);
      }),
    ),
    cardTheme: CardThemeData(
      color: darkBgLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      labelSmall: TextStyle(
        color: textSecondary,
        fontSize: 12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: accentBlue,
      ),
    ),
  );
}


