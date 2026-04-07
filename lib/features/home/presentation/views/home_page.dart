// filepath: c:\Users\clara\StudioProjects\familly_baecon\lib\features\home\presentation\views\home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:familly_baecon/features/journal/presentation/providers/journal_providers.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/profile/presentation/views/profile_page.dart';
import 'package:familly_baecon/features/alertes/presentation/views/alertes_page.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_indicator.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_magnifique.dart';
import 'package:familly_baecon/features/home/presentation/widgets/floor_plan_widget.dart';
import 'package:familly_baecon/features/home/presentation/providers/floor_plan_providers.dart';

import '../../domain/entities/activity.dart';

// ========== PROVIDERS DE TEST ==========
// Mode test : Change la valeur pour tester les différents cas
enum TestMode { real, ok, warning, critical }
enum ActivityStatus { ok, warning, critical }
final testModeProvider = StateProvider<TestMode>((ref) => TestMode.ok); // 🔧 Défaut = OK (phare VERT)

// Provider pour les activités observées - MODE TEST
final testObservedActivitiesProvider = Provider<List<Activity>>((ref) {
  final mode = ref.watch(testModeProvider);
  final date = DateTime(2026, 4, 3); // 🔧 Corrigé à la date du jour

  switch (mode) {
    case TestMode.real:
      // Données réelles depuis le provider normal
      return ref.watch(observedActivitiesProvider);

    case TestMode.ok:
      // Cas OK : 🟢 Toutes les activités correspondent PARFAITEMENT (>85%)
      return [
        Activity(
          id: 'test_ok_1',
          deviceId: 'd_chambre',
          type: 'sleep',
          room: 'CHAMBRE',
          startAt: DateTime(date.year, date.month, date.day, 0, 0),
          endAt: DateTime(date.year, date.month, date.day, 7, 30),
          durationMin: 450,
        ),
        Activity(
          id: 'test_ok_2',
          deviceId: 'd_bathroom',
          type: 'toilettes',
          room: 'SALLE DE BAIN',
          startAt: DateTime(date.year, date.month, date.day, 7, 30),
          endAt: DateTime(date.year, date.month, date.day, 7, 45),
          durationMin: 15,
        ),
        Activity(
          id: 'test_ok_3',
          deviceId: 'd_cuisine',
          type: 'petit-déjeuner',
          room: 'CUISINE',
          startAt: DateTime(date.year, date.month, date.day, 8, 0),
          endAt: DateTime(date.year, date.month, date.day, 8, 30),
          durationMin: 30,
        ),
        Activity(
          id: 'test_ok_4',
          deviceId: 'd_cuisine',
          type: 'déjeuner',
          room: 'CUISINE',
          startAt: DateTime(date.year, date.month, date.day, 12, 0),
          endAt: DateTime(date.year, date.month, date.day, 12, 45),
          durationMin: 45,
        ),
        Activity(
          id: 'test_ok_5',
          deviceId: 'd_salon',
          type: 'activité',
          room: 'SALON',
          startAt: DateTime(date.year, date.month, date.day, 14, 0),
          endAt: DateTime(date.year, date.month, date.day, 16, 0),
          durationMin: 120,
        ),
      ];

    case TestMode.warning:
      // Cas WARNING : 🟡 Écarts modérés (60-75% de correspondance)
      return [
        Activity(
          id: 'test_warn_1',
          deviceId: 'd_chambre',
          type: 'sleep',
          room: 'CHAMBRE',
          startAt: DateTime(date.year, date.month, date.day, 1, 30), // Décalage de 1h30
          endAt: DateTime(date.year, date.month, date.day, 8, 30), // Réveillé 1h tard
          durationMin: 420, // Ratio: 360/450 = 80% (OK mais borderline)
        ),
        Activity(
          id: 'test_warn_2',
          deviceId: 'd_bathroom',
          type: 'toilettes',
          room: 'SALLE DE BAIN',
          startAt: DateTime(date.year, date.month, date.day, 8, 10),
          endAt: DateTime(date.year, date.month, date.day, 8, 30), // ⚠️ Durée augmentée
          durationMin: 20,
        ),
        Activity(
          id: 'test_warn_3',
          deviceId: 'd_cuisine',
          type: 'petit-déjeuner',
          room: 'CUISINE',
          startAt: DateTime(date.year, date.month, date.day, 9, 0), // ⚠️ Décalage de 1h
          endAt: DateTime(date.year, date.month, date.day, 9, 20), // ⚠️ Durée réduite
          durationMin: 20,
        ),
        // ⚠️ Déjeuner très décalé et durée réduite
        Activity(
          id: 'test_warn_4',
          deviceId: 'd_cuisine',
          type: 'déjeuner',
          room: 'CUISINE',
          startAt: DateTime(date.year, date.month, date.day, 13, 30), // ⚠️ 1h30 de retard
          endAt: DateTime(date.year, date.month, date.day, 14, 0), // ⚠️ Durée réduite
          durationMin: 30,
        ),
        // ⚠️ Activité dans une autre pièce
        Activity(
          id: 'test_warn_5',
          deviceId: 'd_chambre',
          type: 'activité',
          room: 'CHAMBRE',
          startAt: DateTime(date.year, date.month, date.day, 15, 30), // ⚠️ 1h30 de retard
          endAt: DateTime(date.year, date.month, date.day, 17, 0),
          durationMin: 90,
        ),
      ];

    case TestMode.critical:
      // Cas CRITICAL : 🔴 Anomalies GRAVES (< 40% de correspondance)
      return [
        // ❌ Sommeil très insuffisant et mauvaise pièce
        Activity(
          id: 'test_crit_1',
          deviceId: 'd_salon',
          type: 'sleep',
          room: 'SALON', // ❌ SALON au lieu de CHAMBRE !
          startAt: DateTime(date.year, date.month, date.day, 3, 0),
          endAt: DateTime(date.year, date.month, date.day, 5, 30),
          durationMin: 150, // ❌ Seulement 2.5h au lieu de 7.5h !
        ),
        // ❌ MANQUE : Toilettes
        // ❌ Petit-déj oublié
        // ❌ Déjeuner oublié

        // Activité bizarre à 10h
        Activity(
          id: 'test_crit_2',
          deviceId: 'd_salon',
          type: 'inactivité',
          room: 'SALON',
          startAt: DateTime(date.year, date.month, date.day, 10, 0),
          endAt: DateTime(date.year, date.month, date.day, 11, 30),
          durationMin: 90,
        ),
        // ❌ Beaucoup d'activité dehors (pas prévu)
        Activity(
          id: 'test_crit_3',
          deviceId: 'd_outside',
          type: 'extérieur',
          room: 'DEHORS',
          startAt: DateTime(date.year, date.month, date.day, 11, 30),
          endAt: DateTime(date.year, date.month, date.day, 15, 0),
          durationMin: 210, // 3.5h dehors non planifiées
        ),
      ];
  }
});

// Provider pour les activités attendues
final testExpectedActivitiesProvider = Provider<List<Activity>>((ref) {
  final mode = ref.watch(testModeProvider);

  if (mode == TestMode.real) {
    return ref.watch(expectedActivitiesProvider);
  }

  // Pour tous les modes test, on utilise les mêmes activités attendues
  final date = DateTime(2026, 4, 3); // 🔧 Corrigé à la date du jour
  return [
    Activity(
      id: 'exp_1',
      deviceId: 'd_chambre',
      type: 'sleep',
      room: 'CHAMBRE',
      startAt: DateTime(date.year, date.month, date.day, 0, 0),
      endAt: DateTime(date.year, date.month, date.day, 7, 30),
      durationMin: 450,
    ),
    Activity(
      id: 'exp_2',
      deviceId: 'd_bathroom',
      type: 'toilettes',
      room: 'SALLE DE BAIN',
      startAt: DateTime(date.year, date.month, date.day, 7, 30),
      endAt: DateTime(date.year, date.month, date.day, 7, 45),
      durationMin: 15,
    ),
    Activity(
      id: 'exp_3',
      deviceId: 'd_cuisine',
      type: 'petit-déjeuner',
      room: 'CUISINE',
      startAt: DateTime(date.year, date.month, date.day, 8, 0),
      endAt: DateTime(date.year, date.month, date.day, 8, 30),
      durationMin: 30,
    ),
    Activity(
      id: 'exp_4',
      deviceId: 'd_cuisine',
      type: 'déjeuner',
      room: 'CUISINE',
      startAt: DateTime(date.year, date.month, date.day, 12, 0),
      endAt: DateTime(date.year, date.month, date.day, 12, 45),
      durationMin: 45,
    ),
    Activity(
      id: 'exp_5',
      deviceId: 'd_salon',
      type: 'activité',
      room: 'SALON',
      startAt: DateTime(date.year, date.month, date.day, 14, 0),
      endAt: DateTime(date.year, date.month, date.day, 16, 0),
      durationMin: 120,
    ),
  ];
});

class HomePage extends ConsumerWidget {
  final Function(int)? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser les providers de test au lieu des vrais providers
    final observed = ref.watch(testObservedActivitiesProvider);
    final expected = ref.watch(testExpectedActivitiesProvider);
    final testMode = ref.watch(testModeProvider);

    // Dernière activité observée
    final lastActivity = observed.isNotEmpty
        ? observed.reduce((a, b) => a.startAt.isAfter(b.startAt) ? a : b)
        : null;

    // 3 dernières activités
    final lastThreeActivities = observed.length >= 3
        ? observed.sublist(observed.length - 3)
        : observed;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header profil cliquable - AMÉLIORÉ
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.accentBlue, AppTheme.accentCyan],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row avec profil et cloche - SIMPLIFIÉ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profil (gauche)
                        Expanded(
                          child: Row(
                            children: [
                              // Avatar avec photo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/rene_profile.svg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom avec indicateur de statut
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Réné Martin',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Mini-phare indicateur
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _getPhareColor(expected, observed),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getPhareColor(expected, observed).withValues(alpha: 0.8),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Dernière activité - HIÉRARCHIE 2
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.greenAccent,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.greenAccent.withValues(alpha: 0.6),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _formatActivityStatus(lastActivity),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Boutons (droite) - Cloche et Debug
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AlertesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            PopupMenuButton<TestMode>(
                              onSelected: (TestMode mode) {
                                ref.read(testModeProvider.notifier).state = mode;
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<TestMode>>[
                                const PopupMenuItem<TestMode>(
                                  value: TestMode.real,
                                  child: Text('🔄 Réel'),
                                ),
                                const PopupMenuItem<TestMode>(
                                  value: TestMode.ok,
                                  child: Text('🟢 OK'),
                                ),
                                const PopupMenuItem<TestMode>(
                                  value: TestMode.warning,
                                  child: Text('🟡 Warning'),
                                ),
                                const PopupMenuItem<TestMode>(
                                  value: TestMode.critical,
                                  child: Text('🔴 Critical'),
                                ),
                              ],
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.bug_report_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Contenu principal avec espacing généreux
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === PHARE INDICATOR (gère la modal) ===
                  PhareIndicator(
                    expected: expected,
                    observed: observed,
                  ),

                  // === PHARE SECTION - MAGNIFIQUE ===
                  GestureDetector(
                    onTap: () {
                      final status = _getPhareStatus(expected, observed);
                      _showPhareModal(context, expected, observed, status);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.darkBg,
                            AppTheme.darkBgLight.withValues(alpha: 0.8),
                          ],
                        ),
                        border: Border.all(
                          color: _getPhareColor(expected, observed).withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getPhareColor(expected, observed).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Titre
                          Text(
                            'Statut Journalier',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Phare magnifique
                          PhareMagnifique(
                            expected: expected,
                            observed: observed,
                          ),

                          const SizedBox(height: 24),

                          // Description dynamique
                          Text(
                            _getPhareDescription(expected, observed),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 20),

                          // Indication "Cliquable"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getPhareColor(expected, observed).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getPhareColor(expected, observed).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 14,
                                      color: _getPhareColor(expected, observed),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Voir les anomalies',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getPhareColor(expected, observed),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // === RÉSUMÉ DU JOUR (EN PREMIER) ===
                  Text(
                    'Résumé du jour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Stats en cartes individuelles
                  _buildDailySummaryStats(observed),
                  const SizedBox(height: 32),

                  // === PLAN DU LOGEMENT (AMÉLIORÉ) ===
                  Consumer(
                    builder: (context, ref, child) {
                      final rooms = ref.watch(roomsProvider);
                      final sensors = ref.watch(sensorsProvider);
                      final selectedRoom = ref.watch(selectedRoomProvider);
                      final activeSensor = ref.watch(activateSensorProvider);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            'Localisation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Carte
                          FloorPlanWidget(
                            rooms: rooms,
                            sensors: sensors,
                            selectedRoomId: selectedRoom,
                            activeSensorId: activeSensor,
                            onRoomTap: (roomId) {
                              ref.read(selectedRoomProvider.notifier).state = roomId;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // === DERNIÈRES ACTIVITÉS - SUPPRIMÉ ===
                  // Section "Dernières activités" has been removed as per requirements
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(Activity activity) {
    if (activity.type.toLowerCase().contains('sleep')) {
      return AppTheme.activityGreen;
    } else if (activity.type.toLowerCase().contains('toilettes')) {
      return AppTheme.accentBlue;
    } else {
      return AppTheme.accentCyan;
    }
  }

  /// Construire le résumé du jour avec des stats pertinentes
  Widget _buildDailySummaryStats(List<Activity> observed) {
    // Compter les repas pris
    int mealsTaken = 0;
    const int expectedMeals = 3; // Petit-déjeuner, Déjeuner, Dîner

    for (final activity in observed) {
      final type = activity.type.toLowerCase();
      final room = (activity.room ?? '').toLowerCase();
      if (type.contains('repas') || type.contains('meal') ||
          type.contains('déjeuner') || type.contains('petit-déjeuner') || type.contains('dîner') ||
          room.contains('cuisine') || room.contains('salle à manger')) {
        mealsTaken++;
      }
    }

    // Calculer le sommeil total
    int sleepMinutes = 0;
    for (final activity in observed) {
      final type = activity.type.toLowerCase();
      final room = (activity.room ?? '').toLowerCase();
      if (type.contains('sleep') || type.contains('sommeil') || room.contains('chambre') || room.contains('lit')) {
        sleepMinutes += (activity.durationMin ?? 0);
      }
    }
    final sleepHours = (sleepMinutes / 60).toStringAsFixed(1);

    // Trouver la dernière sortie
    String lastOutingTime = 'N/A';
    for (int i = observed.length - 1; i >= 0; i--) {
      final activity = observed[i];
      final type = activity.type.toLowerCase();
      final room = (activity.room ?? '').toLowerCase();
      if (type.contains('sortie') || type.contains('outside') || type.contains('déplacement') ||
          room.contains('extérieur') || room.contains('outside')) {
        lastOutingTime = '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}';
        break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatCard(
          label: 'Repas pris',
          value: '$mealsTaken/$expectedMeals',
          icon: Icons.restaurant,
          color: AppTheme.activityOrange,
          flex: 1,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Sommeil',
          value: '${sleepHours}h',
          icon: Icons.bedtime,
          color: AppTheme.activityGreen,
          flex: 1,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Dernière sortie',
          value: lastOutingTime,
          icon: Icons.exit_to_app,
          color: AppTheme.accentBlue,
          flex: 1,
        ),
      ],
    );
  }

  void _showAnomalyDetails(BuildContext context, List<Activity> expected, List<Activity> observed) {
    // Cette méthode a été déplacée dans le widget PhareStatusIndicator
    // Elle n'est plus utilisée ici
  }

  /// Obtenir la couleur du phare basée sur le statut global
  Color _getPhareColor(List<Activity> expected, List<Activity> observed) {
    var worst = ActivityStatus.ok;
    for (final exp in expected) {
      Activity? match;
      for (final obs in observed) {
        if (obs.room == exp.room && obs.type == exp.type) {
          match = obs;
          break;
        }
      }
      if (match == null) {
        for (final obs in observed) {
          if (obs.room == exp.room) {
            match = obs;
            break;
          }
        }
      }
      if (match == null) {
        for (final obs in observed) {
          if (obs.type == exp.type) {
            match = obs;
            break;
          }
        }
      }

      final status = _statusFor(exp, match);
      if (status == ActivityStatus.critical) {
        return const Color(0xFFEF4444); // 🔴 ROUGE
      }
      if (status == ActivityStatus.warning) {
        worst = ActivityStatus.warning;
      }
    }

    if (worst == ActivityStatus.warning) {
      return const Color(0xFFF59E0B); // 🟠 ORANGE
    }
    return const Color(0xFF10B981); // 🟢 VERT
  }

  /// Formater le statut de la dernière activité
  String _formatActivityStatus(Activity? activity) {
    if (activity == null) {
      return 'Aucune activité';
    }

    // Capitaliser le type d'activité
    String typeFormatted = activity.type;
    if (typeFormatted.isNotEmpty) {
      typeFormatted = typeFormatted[0].toUpperCase() + typeFormatted.substring(1);
    }

    // Ajouter l'heure de début
    final timeStr = '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}';

    return '$typeFormatted • $timeStr';
  }

  /// Obtenir la description du phare basée sur le statut
  String _getPhareDescription(List<Activity> expected, List<Activity> observed) {
    final status = _getPhareStatus(expected, observed);

    switch (status) {
      case ActivityStatus.ok:
        return 'Tout va bien ! Les activités correspondent parfaitement à la journée type.';
      case ActivityStatus.warning:
        return 'Quelques écarts détectés. Certaines activités diffèrent légèrement.';
      case ActivityStatus.critical:
        return 'Anomalies détectées. Des écarts importants ont été remarqués.';
    }
  }

  /// Obtenir le statut du phare
  ActivityStatus _getPhareStatus(List<Activity> expected, List<Activity> observed) {
    var worst = ActivityStatus.ok;
    for (final exp in expected) {
      Activity? match;
      for (final obs in observed) {
        if (obs.room == exp.room && obs.type == exp.type) {
          match = obs;
          break;
        }
      }
      if (match == null) {
        for (final obs in observed) {
          if (obs.room == exp.room) {
            match = obs;
            break;
          }
        }
      }
      if (match == null) {
        for (final obs in observed) {
          if (obs.type == exp.type) {
            match = obs;
            break;
          }
        }
      }

      final status = _statusFor(exp, match);
      if (status == ActivityStatus.critical) {
        return ActivityStatus.critical;
      }
      if (status == ActivityStatus.warning) {
        worst = ActivityStatus.warning;
      }
    }

    return worst;
  }

  /// Afficher la modal du phare avec les détails
  void _showPhareModal(BuildContext context, List<Activity> expected, List<Activity> observed, ActivityStatus status) {
    final colors = {
      ActivityStatus.ok: const Color(0xFF10B981),
      ActivityStatus.warning: const Color(0xFFF59E0B),
      ActivityStatus.critical: const Color(0xFFEF4444),
    };

    final labels = {
      ActivityStatus.ok: 'Tout va bien',
      ActivityStatus.warning: 'Anomalie légère',
      ActivityStatus.critical: 'Anomalie grave',
    };

    final descriptions = {
      ActivityStatus.ok: 'Les activités correspondent parfaitement',
      ActivityStatus.warning: 'Quelques écarts détectés',
      ActivityStatus.critical: 'Des anomalies importantes',
    };

    final color = colors[status]!;
    final label = labels[status]!;
    final description = descriptions[status]!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cercle avec icône
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      status == ActivityStatus.ok
                          ? Icons.check_circle_rounded
                          : status == ActivityStatus.warning
                              ? Icons.warning_rounded
                              : Icons.error_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (status != ActivityStatus.ok)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Consultez les détails pour comprendre les anomalies détectées',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculer le statut d'une activité
  ActivityStatus _statusFor(Activity exp, Activity? obs) {
    if (obs == null) return ActivityStatus.warning;
    final sameRoom = exp.room == obs.room;
    if (!sameRoom) return ActivityStatus.critical;
    final expectedDuration = exp.endAt?.difference(exp.startAt).inMinutes ?? 0;
    if (expectedDuration == 0) return ActivityStatus.critical;
    final overlapStart = exp.startAt.isAfter(obs.startAt) ? exp.startAt : obs.startAt;
    final overlapEnd = (exp.endAt ?? exp.startAt).isBefore(obs.endAt ?? obs.startAt)
        ? (exp.endAt ?? exp.startAt)
        : (obs.endAt ?? obs.startAt);
    final overlap = overlapEnd.isAfter(overlapStart)
        ? overlapEnd.difference(overlapStart).inMinutes
        : 0;
    final ratio = overlap / expectedDuration;
    if (ratio >= 0.85) return ActivityStatus.ok;
    if (ratio >= 0.50) return ActivityStatus.warning;
    return ActivityStatus.critical;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon/Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.room ?? activity.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')} - ${activity.endAt?.hour.toString().padLeft(2, '0') ?? '--'}:${activity.endAt?.minute.toString().padLeft(2, '0') ?? '--'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Durée badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${activity.durationMin ?? 0}m',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

