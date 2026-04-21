import 'package:flutter/material.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle sectionLabel;
  final TextStyle infoLabel;
  final TextStyle statValue;

  const AppTypography({
    required this.sectionLabel,
    required this.infoLabel,
    required this.statValue,
  });

  @override
  AppTypography copyWith({
    TextStyle? sectionLabel,
    TextStyle? infoLabel,
    TextStyle? statValue,
  }) {
    return AppTypography(
      sectionLabel: sectionLabel ?? this.sectionLabel,
      infoLabel: infoLabel ?? this.infoLabel,
      statValue: statValue ?? this.statValue,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      infoLabel: TextStyle.lerp(infoLabel, other.infoLabel, t)!,
      statValue: TextStyle.lerp(statValue, other.statValue, t)!,
    );
  }
}

enum AppThemeMode { light, dark }

class AppTheme {
  static const double baseTextScaleMultiplier = 1.2;
  static const double baseIconScaleMultiplier = 1.2;

  // Couleurs neutres (mutables selon le mode). Les accents sont constants
  // pour garder la cohérence des statuts et badges.
  static Color darkBg = const Color(0xFFF0F4F8);
  static Color darkBgLight = const Color(0xFFFFFFFF);
  static Color darkBgLighter = const Color(0xFFE8F1F8);
  static Color textPrimary = const Color(0xFF1A202C);
  static Color textSecondary = const Color(0xFF718096);

  // Accents (identiques en clair/sombre)
  static const Color accentBlue = Color(0xFF0066CC);
  static const Color accentCyan = Color(0xFF0099FF);
  static const Color accentGreen = Color(0xFF10B981);

  // Couleurs activities
  static const Color activityGreen = Color(0xFF10B981);
  static const Color activityRed = Color(0xFFEF4444);
  static const Color activityPurple = Color(0xFF8B5CF6);

  static AppThemeMode _mode = AppThemeMode.light;
  static AppThemeMode get mode => _mode;

  static void applyMode(AppThemeMode mode) {
    _mode = mode;
    if (mode == AppThemeMode.dark) {
      darkBg = const Color(0xFF0F1620);
      darkBgLight = const Color(0xFF1A2230);
      darkBgLighter = const Color(0xFF232D3D);
      textPrimary = const Color(0xFFE6EAF0);
      textSecondary = const Color(0xFF9AA5B4);
    } else {
      darkBg = const Color(0xFFF0F4F8);
      darkBgLight = const Color(0xFFFFFFFF);
      darkBgLighter = const Color(0xFFE8F1F8);
      textPrimary = const Color(0xFF1A202C);
      textSecondary = const Color(0xFF718096);
    }
  }

  static ThemeData buildTheme({
    double textScaleFactor = 1.0,
    double iconScaleFactor = 1.0,
  }) {
    final scaledIcon =
        (iconScaleFactor.clamp(0.8, 1.3)) * baseIconScaleMultiplier;
    final baseText = baseTextScaleMultiplier;
    final onSurfaceColor = textPrimary;
    final secondaryTextColor = textSecondary;
    final surfaceColor = darkBgLight;
    final backgroundColor = darkBg;
    final isDarkMode = _mode == AppThemeMode.dark;
    final borderColor = isDarkMode
        ? const Color(0xFF3A475A)
        : const Color(0xFFBFC7D1);
    final borderColorStrong = isDarkMode
        ? const Color(0xFF4B5B70)
        : const Color(0xFF98A6B8);
    final dividerColor = isDarkMode
        ? const Color(0xFF2D3848)
        : const Color(0xFFC6CED8);

    final isDark = _mode == AppThemeMode.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentBlue,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accentBlue,
              secondary: accentCyan,
              surface: surfaceColor,
              surfaceContainerHighest: darkBgLighter,
              error: activityRed,
              onSurface: onSurfaceColor,
            )
          : ColorScheme.light(
              primary: accentBlue,
              secondary: accentCyan,
              surface: surfaceColor,
              surfaceContainerHighest: darkBgLighter,
              error: activityRed,
              onSurface: onSurfaceColor,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 48,
        titleSpacing: 12,
        titleTextStyle: TextStyle(
          color: onSurfaceColor,
          fontSize: 18 * baseText,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: accentBlue, size: 24 * scaledIcon),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: accentBlue.withValues(alpha: 0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accentBlue, size: 24 * scaledIcon);
          }
          return IconThemeData(
            color: secondaryTextColor,
            size: 24 * scaledIcon,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: accentBlue, fontSize: 12 * baseText);
          }
          return TextStyle(color: secondaryTextColor, fontSize: 12 * baseText);
        }),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.bold,
          fontSize: 32 * baseText,
        ),
        headlineMedium: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.bold,
          fontSize: 24 * baseText,
        ),
        titleLarge: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.bold,
          fontSize: 20 * baseText,
        ),
        titleMedium: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.w700,
          fontSize: 16 * baseText,
        ),
        bodyLarge: TextStyle(color: onSurfaceColor, fontSize: 16 * baseText),
        bodyMedium: TextStyle(
          color: secondaryTextColor,
          fontSize: 14 * baseText,
        ),
        labelSmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 12 * baseText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconTheme: IconThemeData(color: accentBlue, size: 24 * scaledIcon),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: accentBlue,
          iconSize: 24 * scaledIcon,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accentBlue,
        textColor: onSurfaceColor,
        minLeadingWidth: 24 * scaledIcon,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1.2,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColorStrong, width: 1.8),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      extensions: [
        AppTypography(
          sectionLabel: TextStyle(
            color: onSurfaceColor,
            fontSize: 16 * baseText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          infoLabel: TextStyle(
            color: secondaryTextColor,
            fontSize: 12 * baseText,
            fontWeight: FontWeight.w600,
          ),
          statValue: TextStyle(
            color: onSurfaceColor,
            fontSize: 18 * baseText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
