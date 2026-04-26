import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Aucune contrainte d'orientation — le système et les préférences utilisateur
/// décident. Sur téléphone Android, l'utilisateur peut verrouiller dans les
/// paramètres système si besoin.
Future<void> applyDefaultOrientationLock() async {
  await SystemChrome.setPreferredOrientations([]);
}

/// Renvoie true si l'appareil ressemble à une tablette (shortestSide ≥ 600 dp).
/// Utile pour adapter les layouts, pas pour verrouiller l'orientation.
bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}
