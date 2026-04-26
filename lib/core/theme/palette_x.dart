import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
