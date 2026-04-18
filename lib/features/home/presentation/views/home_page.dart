// filepath: c:\Users\clara\StudioProjects\familly_baecon\lib\features\home\presentation\views\home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/alertes/data/entities/alert_item.dart';
import 'package:familly_baecon/features/journal/presentation/providers/journal_providers.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_focus_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';
import 'package:familly_baecon/features/analyse/domain/services/behavior_stats_service.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_magnifique.dart';
import 'package:familly_baecon/features/home/presentation/providers/test_mode_provider.dart';

import '../../domain/entities/activity.dart';

enum ActivityStatus { ok, warning, critical }

// Provider pour les activités observées - MODE TEST
final testObservedActivitiesProvider = Provider<List<Activity>>((ref) {
  final mode = ref.watch(testModeProvider);
  final date = DateTime(2026, 4, 3); // 🔧 Corrigé à la date du jour

  switch (mode) {
    case TestMode.real:
      // Données réelles depuis le provider normal
      return ref.watch(liveObservedActivitiesProvider).valueOrNull ??
          ref.watch(observedActivitiesProvider);

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
          startAt: DateTime(
            date.year,
            date.month,
            date.day,
            1,
            30,
          ), // Décalage de 1h30
          endAt: DateTime(
            date.year,
            date.month,
            date.day,
            8,
            30,
          ), // Réveillé 1h tard
          durationMin: 420, // Ratio: 360/450 = 80% (OK mais borderline)
        ),
        Activity(
          id: 'test_warn_2',
          deviceId: 'd_bathroom',
          type: 'toilettes',
          room: 'SALLE DE BAIN',
          startAt: DateTime(date.year, date.month, date.day, 8, 10),
          endAt: DateTime(
            date.year,
            date.month,
            date.day,
            8,
            30,
          ), // ⚠️ Durée augmentée
          durationMin: 20,
        ),
        Activity(
          id: 'test_warn_3',
          deviceId: 'd_cuisine',
          type: 'petit-déjeuner',
          room: 'CUISINE',
          startAt: DateTime(
            date.year,
            date.month,
            date.day,
            9,
            0,
          ), // ⚠️ Décalage de 1h
          endAt: DateTime(
            date.year,
            date.month,
            date.day,
            9,
            20,
          ), // ⚠️ Durée réduite
          durationMin: 20,
        ),
        // ⚠️ Déjeuner très décalé et durée réduite
        Activity(
          id: 'test_warn_4',
          deviceId: 'd_cuisine',
          type: 'déjeuner',
          room: 'CUISINE',
          startAt: DateTime(
            date.year,
            date.month,
            date.day,
            13,
            30,
          ), // ⚠️ 1h30 de retard
          endAt: DateTime(
            date.year,
            date.month,
            date.day,
            14,
            0,
          ), // ⚠️ Durée réduite
          durationMin: 30,
        ),
        // ⚠️ Activité dans une autre pièce
        Activity(
          id: 'test_warn_5',
          deviceId: 'd_chambre',
          type: 'activité',
          room: 'CHAMBRE',
          startAt: DateTime(
            date.year,
            date.month,
            date.day,
            15,
            30,
          ), // ⚠️ 1h30 de retard
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
    final textTheme = Theme.of(context).textTheme;
    final appTypography = Theme.of(context).extension<AppTypography>();
    final sectionLabelStyle =
        appTypography?.sectionLabel ??
        textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
          letterSpacing: 0.3,
        );
    // Utiliser les providers de test au lieu des vrais providers
    final observed = ref.watch(testObservedActivitiesProvider);
    final expected = ref.watch(testExpectedActivitiesProvider);
    final observedFromBackend =
        ref.watch(liveObservedActivitiesProvider).valueOrNull ??
        const <Activity>[];
    ref.watch(liveAlertsProvider);

    ref.listen(liveAlertsProvider, (previous, next) {
      final alerts = next.valueOrNull;
      if (alerts == null || alerts.isEmpty) return;
      final latest = alerts.first;
      final lastShown = ref.read(lastPopupAlertIdProvider);
      if (latest.id == lastShown) return;
      ref.read(lastPopupAlertIdProvider.notifier).state = latest.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showRealtimeAlertDialog(context, ref, latest, expected, observed);
      });
    });

    final observedForLastActivity = observedFromBackend.isNotEmpty
        ? observedFromBackend
        : observed;
    final anomalies = ref.watch(liveAnomaliesProvider).valueOrNull ?? const [];
    final hasLatestAnomaly = anomalies.isNotEmpty;
    final phareStatus = hasLatestAnomaly
        ? _getPhareStatus(expected, observed)
        : ActivityStatus.ok;
    final phareColor = switch (phareStatus) {
      ActivityStatus.ok => const Color(0xFF10B981),
      ActivityStatus.warning => const Color(0xFFF59E0B),
      ActivityStatus.critical => const Color(0xFFEF4444),
    };
    final lastActivity = observedForLastActivity.isEmpty
        ? null
        : observedForLastActivity.reduce(
            (a, b) => a.startAt.isAfter(b.startAt) ? a : b,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final latestLocation = observedForLastActivity.isEmpty
              ? null
              : observedForLastActivity.reduce(
                  (a, b) => a.startAt.isAfter(b.startAt) ? a : b,
                );

          final avatarSize = isWide ? 96.0 : 72.0;
          final avatar = Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkBgLight,
              border: Border.all(
                color: AppTheme.accentBlue.withValues(alpha: 0.18),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(avatarSize),
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Image.asset(
                  'assets/elderly_avatar.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );

          final nameText = Text(
            'René',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          );

          final infoCard = Container(
            decoration: BoxDecoration(
              color: AppTheme.darkBgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoTile(
                  icon: Icons.history_rounded,
                  iconColor: AppTheme.accentBlue,
                  label: 'Dernière activité',
                  value: _formatLastActivityValue(lastActivity),
                ),
                Divider(
                  height: 18,
                  thickness: 1,
                  color: AppTheme.textSecondary.withValues(alpha: 0.10),
                ),
                _InfoTile(
                  icon: Icons.place_outlined,
                  iconColor: AppTheme.accentCyan,
                  label: 'Dernière localisation',
                  value: _formatLatestLocationValue(latestLocation),
                ),
              ],
            ),
          );

          Widget buildPhare({
            required double width,
            required double height,
            required double lighthouseSize,
          }) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhareMagnifique(
                  expected: expected,
                  observed: observed,
                  hasActiveAnomaly: hasLatestAnomaly,
                  width: width,
                  height: height,
                  lighthouseSize: lighthouseSize,
                ),
                if (hasLatestAnomaly) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _showPhareModal(
                        context,
                        expected,
                        observed,
                        phareStatus,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: phareColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('En savoir plus'),
                  ),
                ],
              ],
            );
          }

          final phonePhare = buildPhare(
            width: 260,
            height: 210,
            lighthouseSize: 190,
          );

          final summarySection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Résumé du jour', style: sectionLabelStyle),
              const SizedBox(height: 14),
              _buildDailySummaryStats(observedForLastActivity),
            ],
          );

          if (isWide) {
            // Tablette : layout deux colonnes, pas de scroll.
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              avatar,
                              const SizedBox(height: 10),
                              nameText,
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        infoCard,
                        const Spacer(),
                        summarySection,
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: LayoutBuilder(
                      builder: (context, slot) {
                        // Phare = carré ~5/6 d'aspect (260x210). On prend
                        // tout l'espace dispo en respectant ce ratio.
                        const aspect = 260 / 210;
                        final reserveBtn = hasLatestAnomaly ? 56.0 : 0.0;
                        final maxH = slot.maxHeight - reserveBtn;
                        final maxW = slot.maxWidth;
                        var w = maxW;
                        var h = w / aspect;
                        if (h > maxH) {
                          h = maxH;
                          w = h * aspect;
                        }
                        return Center(
                          child: buildPhare(
                            width: w,
                            height: h,
                            lighthouseSize: h * 0.9,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Téléphone : layout vertical, scrollable.
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        avatar,
                        const SizedBox(height: 10),
                        nameText,
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  infoCard,
                  const SizedBox(height: 20),
                  Center(child: phonePhare),
                  const SizedBox(height: 28),
                  summarySection,
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
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
    final dayStats = BehaviorStatsService.summarizeLatestDay(observed);
    const expectedMeals = 3;
    final sleepHours = (dayStats.sleepMinutes / 60).toStringAsFixed(1);
    final latestOther = observed.isEmpty
        ? null
        : observed
              .where((activity) {
                final type = activity.type.toLowerCase();
                return !(type.contains('sleep') ||
                    type.contains('sommeil') ||
                    type.contains('petit_dejeuner') ||
                    type.contains('petit-déjeuner') ||
                    type.contains('dejeuner') ||
                    type.contains('déjeuner') ||
                    type.contains('souper') ||
                    type.contains('repas'));
              })
              .fold<Activity?>(
                null,
                (prev, current) =>
                    prev == null || current.startAt.isAfter(prev.startAt)
                    ? current
                    : prev,
              );
    final latestOtherTime = latestOther == null
        ? 'N/A'
        : '${latestOther.startAt.hour.toString().padLeft(2, '0')}:${latestOther.startAt.minute.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatCard(
          label: 'Repas pris',
          value: '${dayStats.mealsCount}/$expectedMeals',
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
          label: 'Dernière activité',
          value: latestOtherTime,
          icon: Icons.exit_to_app,
          color: AppTheme.accentBlue,
          flex: 1,
        ),
      ],
    );
  }

  /// Obtenir le statut du phare
  ActivityStatus _getPhareStatus(
    List<Activity> expected,
    List<Activity> observed,
  ) {
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
  void _showPhareModal(
    BuildContext context,
    List<Activity> expected,
    List<Activity> observed,
    ActivityStatus status,
  ) {
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                  if (status != ActivityStatus.ok)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final anomalies = await ProviderScope.containerOf(
                            context,
                            listen: false,
                          ).read(liveAnomaliesProvider.future);
                          final latestId = anomalies.isNotEmpty
                              ? anomalies.first.id
                              : null;
                          if (latestId != null) {
                            ProviderScope.containerOf(context, listen: false)
                                    .read(focusedAnomalyIdProvider.notifier)
                                    .state =
                                latestId;
                          }
                          onNavigate?.call(2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.activityOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Voir l’anomalie',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
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

  void _showRealtimeAlertDialog(
    BuildContext context,
    WidgetRef ref,
    AlertItem alert,
    List<Activity> expected,
    List<Activity> observed,
  ) {
    final isHigh = alert.severity == 'high';
    final accentColor = isHigh ? AppTheme.activityRed : AppTheme.activityOrange;
    final textTheme = Theme.of(context).textTheme;
    final iconSize = Theme.of(context).iconTheme.size ?? 24;
    final priorityText = isHigh ? 'Priorité haute' : 'Priorité moyenne';
    final icon = isHigh
        ? Icons.priority_high_rounded
        : Icons.warning_amber_rounded;
    final typeLabel = _anomalyLabel(alert.anomalyType);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.84,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: accentColor, size: iconSize),
                        const SizedBox(width: 8),
                        Text(
                          'Anomalie détectée',
                          style: TextStyle(
                            fontSize: textTheme.titleLarge?.fontSize ?? 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$priorityText • $typeLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: textTheme.bodySmall?.fontSize ?? 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: textTheme.bodyMedium?.fontSize,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 210,
                      child: PhareMagnifique(
                        expected: expected,
                        observed: observed,
                        alertSeverity: alert.severity,
                        forceGyrophare: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Plus tard'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              final anomalies = await ref.read(
                                liveAnomaliesProvider.future,
                              );
                              if (!context.mounted) return;
                              final latestId = anomalies.isNotEmpty
                                  ? anomalies.first.id
                                  : null;
                              if (latestId != null) {
                                ref
                                        .read(focusedAnomalyIdProvider.notifier)
                                        .state =
                                    latestId;
                              }
                              onNavigate?.call(2);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                            ),
                            child: const Text('Voir l’anomalie'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _anomalyLabel(String anomalyType) {
    return switch (anomalyType) {
      'missing' => 'Activité manquante',
      'timing' => 'Horaire inhabituel',
      'duration_short' => 'Durée courte',
      'duration_long' => 'Durée longue',
      'freq_high' => 'Fréquence élevée',
      'freq_low' => 'Fréquence faible',
      _ => anomalyType,
    };
  }

  /// Calculer le statut d'une activité
  ActivityStatus _statusFor(Activity exp, Activity? obs) {
    if (obs == null) return ActivityStatus.warning;
    final sameRoom = exp.room == obs.room;
    if (!sameRoom) return ActivityStatus.critical;
    final expectedDuration = exp.endAt?.difference(exp.startAt).inMinutes ?? 0;
    if (expectedDuration == 0) return ActivityStatus.critical;
    final overlapStart = exp.startAt.isAfter(obs.startAt)
        ? exp.startAt
        : obs.startAt;
    final overlapEnd =
        (exp.endAt ?? exp.startAt).isBefore(obs.endAt ?? obs.startAt)
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

  String _formatLastActivityValue(Activity? activity) {
    if (activity == null) return '—';
    final typeFormatted = activity.type.isEmpty
        ? 'Activité'
        : '${activity.type[0].toUpperCase()}${activity.type.substring(1)}';
    final time =
        '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}';
    return '$typeFormatted • $time';
  }

  String _formatLatestLocationValue(Activity? activity) {
    if (activity == null) return 'Inconnue';
    final time =
        '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')}';
    return '${activity.room ?? 'Inconnue'} • $time';
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
    final appTypography = Theme.of(context).extension<AppTypography>();
    final infoLabelStyle =
        appTypography?.infoLabel ??
        TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        );
    final statValueStyle =
        appTypography?.statValue ??
        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color);

    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkBgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: statValueStyle.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: infoLabelStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
