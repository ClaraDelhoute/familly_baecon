enum AnomalyType {
  missing,
  timing,
  durationLong,
  durationShort,
  freqHigh,
  freqLow,
  unknown;

  static AnomalyType fromKey(String raw) {
    return switch (raw.toLowerCase()) {
      'missing' => AnomalyType.missing,
      'timing' => AnomalyType.timing,
      'duration_long' => AnomalyType.durationLong,
      'duration_short' => AnomalyType.durationShort,
      'freq_high' => AnomalyType.freqHigh,
      'freq_low' => AnomalyType.freqLow,
      _ => AnomalyType.unknown,
    };
  }

  static AnomalyType inferFromMessage(String lowerMessage) {
    if (lowerMessage.contains('missing') || lowerMessage.contains('manquant')) {
      return AnomalyType.missing;
    }
    if (lowerMessage.contains('duration_long') ||
        lowerMessage.contains('durée longue') ||
        lowerMessage.contains('anormalement longue') ||
        lowerMessage.contains('trop long')) {
      return AnomalyType.durationLong;
    }
    if (lowerMessage.contains('duration_short') ||
        lowerMessage.contains('durée courte') ||
        lowerMessage.contains('anormalement courte') ||
        lowerMessage.contains('trop court') ||
        lowerMessage.contains('trop courte')) {
      return AnomalyType.durationShort;
    }
    if (lowerMessage.contains('freq_high') ||
        lowerMessage.contains('fréquence élevée') ||
        lowerMessage.contains('trop fréquent')) {
      return AnomalyType.freqHigh;
    }
    if (lowerMessage.contains('freq_low') ||
        lowerMessage.contains('fréquence faible') ||
        lowerMessage.contains('rare')) {
      return AnomalyType.freqLow;
    }
    if (lowerMessage.contains('timing') ||
        lowerMessage.contains('horaire') ||
        lowerMessage.contains('inhabituel')) {
      return AnomalyType.timing;
    }
    return AnomalyType.timing;
  }
}

extension AnomalyTypeX on AnomalyType {
  String get backendKey => switch (this) {
        AnomalyType.missing => 'missing',
        AnomalyType.timing => 'timing',
        AnomalyType.durationLong => 'duration_long',
        AnomalyType.durationShort => 'duration_short',
        AnomalyType.freqHigh => 'freq_high',
        AnomalyType.freqLow => 'freq_low',
        AnomalyType.unknown => 'unknown',
      };

  String get severity => switch (this) {
        AnomalyType.missing ||
        AnomalyType.durationLong ||
        AnomalyType.freqHigh => 'high',
        _ => 'medium',
      };

  String get label => switch (this) {
        AnomalyType.missing => 'Activité manquante',
        AnomalyType.timing => 'Horaire inhabituel',
        AnomalyType.durationLong => 'Durée plus longue que d\'habitude',
        AnomalyType.durationShort => 'Durée plus courte que d\'habitude',
        AnomalyType.freqHigh => 'Fréquence anormalement élevée',
        AnomalyType.freqLow => 'Fréquence anormalement basse',
        AnomalyType.unknown => 'Comportement inhabituel',
      };

  String get shortDescription => label;

  String get explanation => switch (this) {
        AnomalyType.missing =>
          'Une activité habituellement observée à cette heure n\'a pas été détectée. '
              'Cela peut indiquer un changement de routine ou nécessiter une vérification.',
        AnomalyType.timing =>
          'Cette activité a été réalisée à un horaire significativement différent de la routine habituelle. '
              'Un décalage ponctuel est normal, mais un changement persistant mérite attention.',
        AnomalyType.durationLong =>
          'La durée de cette activité est anormalement longue par rapport aux habitudes. '
              'Cela peut refléter une fatigue, une difficulté ou simplement un changement de rythme.',
        AnomalyType.durationShort =>
          'Cette activité a été réalisée plus rapidement que d\'habitude. '
              'Dans certains cas, cela peut indiquer une précipitation ou une interruption.',
        AnomalyType.freqHigh =>
          'Cette activité a été observée plus souvent que la normale sur la période récente. '
              'Une fréquence élevée peut parfois être le signe d\'une gêne ou d\'une préoccupation.',
        AnomalyType.freqLow =>
          'Cette activité a été réalisée moins souvent que d\'habitude. '
              'Une baisse de fréquence peut indiquer une modification volontaire ou une difficulté.',
        AnomalyType.unknown =>
          'Un comportement inhabituel a été détecté. '
              'Les données disponibles ne permettent pas de préciser davantage la nature de l\'anomalie.',
      };

  String phraseFor(String? activity) {
    final a = activity ?? "l'activité";
    return switch (this) {
      AnomalyType.missing => '$a n\'a pas été détecté${_eAccord(a)}.',
      AnomalyType.timing => '$a a eu lieu à un horaire inhabituel.',
      AnomalyType.durationLong => '$a a duré plus longtemps que d\'habitude.',
      AnomalyType.durationShort => '$a a duré moins longtemps que d\'habitude.',
      AnomalyType.freqHigh => '$a a été observé${_eAccord(a)} plus souvent que d\'habitude.',
      AnomalyType.freqLow => '$a a été observé${_eAccord(a)} moins souvent que d\'habitude.',
      AnomalyType.unknown => 'Un comportement inhabituel lié à $a a été détecté.',
    };
  }
}

String _eAccord(String subject) {
  final s = subject.toLowerCase();
  if (s.startsWith('la ') ||
      s.startsWith('l\'a') ||
      s.startsWith("l'a")) {
    return 'e';
  }
  return '';
}
