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

class AppTheme {
  static const double baseTextScaleMultiplier = 1.2;
  static const double baseIconScaleMultiplier = 1.2;

  // Couleurs - Thème bleu-clair modernisé
  static const Color darkBg = Color(0xFFF0F4F8); // Blanc-bleu très clair
  static const Color darkBgLight = Color(0xFFFFFFFF); // Blanc pur
  static const Color darkBgLighter = Color(0xFFE8F1F8); // Très clair bleu
  static const Color accentBlue = Color(0xFF0066CC); // Bleu électrique
  static const Color accentCyan = Color(0xFF0099FF); // Bleu ciel
  static const Color accentGreen = Color(0xFF10B981); // Vert clair
  static const Color textPrimary = Color(0xFF1A202C); // Bleu-noir foncé
  static const Color textSecondary = Color(0xFF718096); // Gris-bleu modéré

  // Couleurs activities
  static const Color activityGreen = Color(0xFF10B981);
  static const Color activityOrange = Color(0xFFF59E0B);
  static const Color activityRed = Color(0xFFEF4444);

  static ThemeData buildTheme({
    double textScaleFactor = 1.0,
    double iconScaleFactor = 1.0,
    bool highContrast = false,
  }) {
    final scaledIcon =
        (iconScaleFactor.clamp(0.8, 1.8)) * baseIconScaleMultiplier;
    final baseText = baseTextScaleMultiplier;
    final onSurfaceColor = highContrast ? const Color(0xFF111111) : textPrimary;
    final secondaryTextColor = highContrast
        ? const Color(0xFF1F2937)
        : textSecondary;
    final surfaceColor = highContrast ? Colors.white : darkBgLight;
    final backgroundColor = highContrast ? const Color(0xFFF7F9FC) : darkBg;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentBlue,
      colorScheme: ColorScheme.light(
        primary: accentBlue,
        secondary: accentCyan,
        surface: surfaceColor,
        surfaceContainerHighest: highContrast
            ? const Color(0xFFE5EAF2)
            : darkBgLighter,
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
        indicatorColor: accentBlue.withValues(alpha: highContrast ? 0.2 : 0.1),
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
        elevation: highContrast ? 5 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFBFC7D1), width: 1.5),
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
          side: const BorderSide(color: Color(0xFFCCD3DC), width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFC6CED8),
        thickness: 1.2,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFBFC7D1), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFBFC7D1), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF98A6B8), width: 1.8),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFBFC7D1), width: 1.5),
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
