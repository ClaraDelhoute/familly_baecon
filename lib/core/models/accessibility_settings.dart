class AccessibilitySettings {
  final double textScaleFactor;
  final double iconScaleFactor;

  const AccessibilitySettings({
    required this.textScaleFactor,
    required this.iconScaleFactor,
  });

  AccessibilitySettings copyWith({
    double? textScaleFactor,
    double? iconScaleFactor,
  }) {
    return AccessibilitySettings(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      iconScaleFactor: iconScaleFactor ?? this.iconScaleFactor,
    );
  }
}
