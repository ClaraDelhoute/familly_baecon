import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Verrouille l'orientation portrait sur téléphone, libre sur tablette.
/// Heuristique standard : téléphone si shortestSide < 600 dp.
Future<void> applyDefaultOrientationLock() async {
  if (_isPhone()) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}

bool _isPhone() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  final shortestSide = size.shortestSide;
  return shortestSide < 600;
}

/// Pour usage hors `WidgetsBinding` (ex. avant ensureInitialized).
double currentShortestSideDp() {
  final view = PlatformDispatcher.instance.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return size.shortestSide;
}
