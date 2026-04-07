/// Classe pour générer des explications personnalisées des anomalies
class AnomalyExplainer {
  /// Génère une explication basée sur l'activité attendue et l'activité observée
  static String generateExplanation({
    required String activityType,
    required String expectedRoom,
    required String? observedRoom,
    required DateTime expectedTime,
    required DateTime? observedTime,
  }) {
    // Si pas d'activité observée
    if (observedRoom == null || observedTime == null) {
      return _getMissingActivityExplanation(activityType, expectedRoom, expectedTime);
    }

    // Si pièce erronée
    if (expectedRoom.toLowerCase() != observedRoom.toLowerCase()) {
      return _getWrongLocationExplanation(activityType, expectedRoom, observedRoom);
    }

    // Si timing décalé
    final timeDiff = observedTime.difference(expectedTime).inMinutes.abs();
    if (timeDiff > 30) {
      return _getTimingOffExplanation(activityType, timeDiff);
    }

    // Cas normal (pas d'anomalie)
    return 'L\'activité "$activityType" s\'est déroulée normalement.';
  }

  static String _getMissingActivityExplanation(
    String activityType,
    String room,
    DateTime time,
  ) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    final explanations = {
      'sleep': 'Réné n\'a pas dormi à l\'heure prévue ($hour:$minute). C\'est peut-être une nuit courte ou difficile.',
      'toilettes': 'Pas de visite aux toilettes détectée à $hour:$minute. À vérifier.',
      'petit-déjeuner': 'Réné n\'a pas pris son petit-déjeuner à $hour:$minute. Vérifiez s\'il a mangé plus tard.',
      'déjeuner': 'Le repas de midi n\'a pas été détecté à $hour:$minute.',
      'dîner': 'Le dîner n\'a pas eu lieu à l\'heure habituelle ($hour:$minute).',
      'activité': 'Aucune activité n\'a été détectée à $hour:$minute. Réné était peut-être inactif.',
    };

    return explanations[activityType.toLowerCase()] ??
        'L\'activité "$activityType" attendue à $hour:$minute n\'a pas été détectée.';
  }

  static String _getWrongLocationExplanation(
    String activityType,
    String expectedRoom,
    String observedRoom,
  ) {
    final explanations = {
      'sleep': 'Réné a dormi dans la $observedRoom au lieu de la $expectedRoom. Changement de routine.',
      'toilettes': 'Les toilettes utilisées ne sont pas la salle de bain habituelle.',
      'petit-déjeuner': 'Réné a petit-déjeuné dans la $observedRoom au lieu de la $expectedRoom.',
      'déjeuner': 'Le déjeuner a eu lieu dans la $observedRoom au lieu de la $expectedRoom.',
      'dîner': 'Le dîner s\'est déroulé dans la $observedRoom au lieu de la $expectedRoom.',
      'activité': 'Réné était dans la $observedRoom au lieu de la $expectedRoom.',
    };

    return explanations[activityType.toLowerCase()] ??
        'L\'activité "$activityType" s\'est déroulée dans la $observedRoom au lieu de la $expectedRoom.';
  }

  static String _getTimingOffExplanation(
    String activityType,
    int minutesDifference,
  ) {
    final isLate = minutesDifference > 0;
    final direction = isLate ? 'plus tard' : 'plus tôt';

    final explanations = {
      'sleep': 'Réné s\'est couché $direction. Décalage de $minutesDifference minutes.',
      'toilettes': 'Les toilettes ont été utilisées $direction de $minutesDifference minutes.',
      'petit-déjeuner': 'Petit-déjeuner décalé de $minutesDifference minutes ($direction).',
      'déjeuner': 'Déjeuner $direction de $minutesDifference minutes.',
      'dîner': 'Dîner $direction de $minutesDifference minutes.',
      'activité': 'Activité décalée $direction. Différence : $minutesDifference minutes.',
    };

    return explanations[activityType.toLowerCase()] ??
        'L\'activité "$activityType" s\'est déroulée $direction ($minutesDifference min).';
  }
}

