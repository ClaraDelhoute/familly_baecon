class AccessibilitySettings {
  final double textScaleFactor;
  final double iconScaleFactor;
  final bool highContrast;

  const AccessibilitySettings({
    required this.textScaleFactor,
    required this.iconScaleFactor,
    required this.highContrast,
  });

  AccessibilitySettings copyWith({
    double? textScaleFactor,
    double? iconScaleFactor,
    bool? highContrast,
  }) {
    return AccessibilitySettings(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      iconScaleFactor: iconScaleFactor ?? this.iconScaleFactor,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}
