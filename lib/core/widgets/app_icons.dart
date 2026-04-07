import 'package:flutter/material.dart';

/// Gestionnaire centralisé des icônes pour éviter les incohérences
class AppIcons {
  // Navigation
  static const IconData home = Icons.home;
  static const IconData calendar = Icons.calendar_today;
  static const IconData analysis = Icons.show_chart;
  static const IconData notifications = Icons.notifications_none;

  // Actions
  static const IconData close = Icons.close;
  static const IconData location = Icons.location_on_outlined;
  static const IconData map = Icons.map;
  static const IconData settings = Icons.settings;

  // Status
  static const IconData checkCircle = Icons.check_circle;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_outline;
  static const IconData info = Icons.info;

  // Activities
  static const IconData timeline = Icons.timeline;
  static const IconData timer = Icons.timer;
  static const IconData profile = Icons.person;
  static const IconData stats = Icons.bar_chart;

  // UI
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData notificationsOff = Icons.notifications_off;

  /// Build une icône avec gestion des erreurs
  static Icon buildIcon(
    IconData icon, {
    double size = 24.0,
    Color? color,
    String? semanticLabel,
  }) {
    return Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}

