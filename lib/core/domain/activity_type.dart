import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

enum ActivityType {
  sleep,
  breakfast,
  lunch,
  dinner,
  toilet,
  shower,
  outside,
  television,
  computer,
  activity,
  inactivity,
  unknown;

  // Exact key matching (anomaly activityKey values)
  static ActivityType fromKey(String raw) {
    return switch (raw.toLowerCase()) {
      'sleep' => ActivityType.sleep,
      'petit-déjeuner' || 'petit_dejeuner' || 'breakfast' => ActivityType.breakfast,
      'déjeuner' || 'dejeuner' || 'lunch' => ActivityType.lunch,
      'souper' || 'dinner' || 'dîner' => ActivityType.dinner,
      'toilette' || 'toilettes' || 'toilet' => ActivityType.toilet,
      'douche' || 'shower' => ActivityType.shower,
      'outside' || 'sortie' || 'déplacement' => ActivityType.outside,
      'television' || 'tv' || 'télévision' => ActivityType.television,
      'ordinateur' || 'computer' => ActivityType.computer,
      'daily_activity' || 'activity' => ActivityType.activity,
      'inactivity' || 'inactivité' => ActivityType.inactivity,
      _ => ActivityType.unknown,
    };
  }

  // Substring matching (raw sensor/activity type strings)
  static ActivityType fromTypeContains(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('sleep') || t.contains('sommeil')) return ActivityType.sleep;
    if (t.contains('petit') && (t.contains('dej') || t.contains('déj'))) {
      return ActivityType.breakfast;
    }
    if (t.contains('breakfast')) return ActivityType.breakfast;
    if (t.contains('lunch') || (t.contains('dej') && !t.contains('petit'))) {
      return ActivityType.lunch;
    }
    if (t.contains('dinner') || t.contains('souper') || t.contains('dîner')) {
      return ActivityType.dinner;
    }
    if (t.contains('meal') || t.contains('repas')) return ActivityType.lunch;
    if (t.contains('douche') || t.contains('shower')) return ActivityType.shower;
    if (t.contains('toilet') || t.contains('toilettes')) return ActivityType.toilet;
    if (t.contains('outside') || t.contains('sortie') || t.contains('déplacement')) {
      return ActivityType.outside;
    }
    if (t.contains('tv') || t.contains('television') || t.contains('télévision')) {
      return ActivityType.television;
    }
    if (t.contains('ordinateur') || t.contains('computer')) return ActivityType.computer;
    if (t.contains('inactiv')) return ActivityType.inactivity;
    return ActivityType.unknown;
  }

  // Room string matching (for schedule category matching via room field)
  static ActivityType fromRoom(String room) {
    final r = room.toLowerCase();
    if (r.contains('chambre') || r.contains('lit')) return ActivityType.sleep;
    if (r.contains('salle de bain') || r.contains('toilet')) return ActivityType.toilet;
    if (r.contains('cuisine') || r.contains('salle à manger')) return ActivityType.lunch;
    if (r.contains('extérieur')) return ActivityType.outside;
    return ActivityType.unknown;
  }
}

extension ActivityTypeX on ActivityType {
  bool get isSleep => this == ActivityType.sleep;

  bool get isMeal =>
      this == ActivityType.breakfast ||
      this == ActivityType.lunch ||
      this == ActivityType.dinner;

  bool get isHygiene =>
      this == ActivityType.toilet || this == ActivityType.shower;

  String get label => switch (this) {
        ActivityType.sleep => 'Sommeil',
        ActivityType.breakfast => 'Petit-déjeuner',
        ActivityType.lunch => 'Déjeuner',
        ActivityType.dinner => 'Souper',
        ActivityType.toilet => 'Toilettes',
        ActivityType.shower => 'Douche',
        ActivityType.outside => 'Sortie',
        ActivityType.television => 'Télévision',
        ActivityType.computer => 'Ordinateur',
        ActivityType.activity => 'Activité quotidienne',
        ActivityType.inactivity => 'Inactivité',
        ActivityType.unknown => 'Activité',
      };

  String get subject => switch (this) {
        ActivityType.sleep => 'le sommeil',
        ActivityType.breakfast => 'le petit-déjeuner',
        ActivityType.lunch => 'le déjeuner',
        ActivityType.dinner => 'le souper',
        ActivityType.toilet => 'les toilettes',
        ActivityType.shower => 'la douche',
        ActivityType.outside => 'la sortie',
        ActivityType.television => 'la télévision',
        ActivityType.computer => "l'ordinateur",
        ActivityType.activity => "l'activité quotidienne",
        ActivityType.inactivity => "l'inactivité",
        ActivityType.unknown => "l'activité",
      };

  String get category => switch (this) {
        ActivityType.sleep => 'sleep',
        ActivityType.breakfast ||
        ActivityType.lunch ||
        ActivityType.dinner => 'meal',
        ActivityType.toilet || ActivityType.shower => 'hygiene',
        ActivityType.outside => 'out',
        _ => 'other',
      };

  IconData get icon => switch (this) {
        ActivityType.sleep => Icons.bedtime_rounded,
        ActivityType.breakfast => Icons.free_breakfast_rounded,
        ActivityType.lunch => Icons.restaurant_rounded,
        ActivityType.dinner => Icons.ramen_dining_rounded,
        ActivityType.toilet || ActivityType.shower => Icons.bathtub_rounded,
        ActivityType.outside => Icons.directions_walk_rounded,
        ActivityType.television => Icons.tv_rounded,
        ActivityType.computer => Icons.computer_rounded,
        ActivityType.activity => Icons.timeline_rounded,
        _ => Icons.info_outline_rounded,
      };

  Color get color => switch (this) {
        ActivityType.sleep => AppTheme.activityGreen,
        ActivityType.toilet || ActivityType.shower => AppTheme.accentBlue,
        ActivityType.television => AppTheme.accentCyan,
        ActivityType.computer => const Color(0xFFBB86FC),
        _ => AppTheme.activityPurple,
      };

  String get emoji => switch (this) {
        ActivityType.sleep => '😴',
        ActivityType.breakfast ||
        ActivityType.lunch ||
        ActivityType.dinner => '🍽️',
        ActivityType.toilet || ActivityType.shower => '🚿',
        ActivityType.outside => '🚶',
        _ => '📍',
      };
}
