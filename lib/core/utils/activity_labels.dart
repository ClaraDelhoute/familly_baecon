/// Traduit un type d'activité (valeur brute backend) en libellé français.
String activityTypeLabel(String type) {
  final t = type.toLowerCase().trim();
  if (t == 'sleep' || t == 'sommeil') return 'Sommeil';
  if (t == 'petit_dejeuner' || t == 'petit-déjeuner' || t == 'petit-dejeuner') return 'Petit-déjeuner';
  if (t == 'dejeuner' || t == 'déjeuner') return 'Déjeuner';
  if (t == 'souper' || t == 'dîner' || t == 'diner') return 'Souper';
  if (t == 'toilette' || t == 'toilettes') return 'Toilettes';
  if (t == 'sortie' || t == 'outside' || t == 'extérieur') return 'Sortie';
  if (t == 'inactivité' || t == 'inactivite') return 'Inactivité';
  if (t == 'activité' || t == 'activite') return 'Activité';
  // Capitalise la première lettre pour tout type inconnu
  if (t.isEmpty) return 'Activité';
  return '${type[0].toUpperCase()}${type.substring(1)}';
}

/// Traduit un nom de room (valeur brute backend) en libellé français.
String roomLabel(String? room) {
  if (room == null || room.isEmpty) return 'Inconnue';
  final r = room.toLowerCase().trim();
  if (r == 'outside' || r == 'dehors' || r == 'extérieur') return 'Extérieur';
  if (r == 'salle_de_bain' || r == 'salle de bain' || r == 'sdb' || r == 'bathroom') return 'Salle de bain';
  if (r == 'salon' || r == 'living') return 'Salon';
  if (r == 'cuisine' || r == 'kitchen') return 'Cuisine';
  if (r == 'chambre' || r == 'bedroom') return 'Chambre';
  if (r == 'toilettes' || r == 'wc' || r == 'toilet') return 'Toilettes';
  // Capitalise sinon
  return '${room[0].toUpperCase()}${room.substring(1)}';
}
