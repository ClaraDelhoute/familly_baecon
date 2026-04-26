// filepath: c:\Users\clara\StudioProjects\familly_baecon\lib\features\home\presentation\views\home_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/alertes/data/entities/alert_item.dart';
import 'package:familly_baecon/features/journal/presentation/providers/journal_providers.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_focus_provider.dart';
import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/core/domain/anomaly_type.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/providers/profile_image_provider.dart';
import 'package:familly_baecon/core/providers/watched_person_provider.dart';
import 'package:familly_baecon/features/settings/presentation/views/settings_page.dart';
import 'package:familly_baecon/features/analyse/domain/services/behavior_stats_service.dart';
import 'package:familly_baecon/features/analyse/presentation/providers/stats_summary_provider.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_magnifique.dart';
import 'package:familly_baecon/core/utils/activity_labels.dart';
import 'package:familly_baecon/features/home/presentation/providers/test_mode_provider.dart';
import 'package:familly_baecon/features/journal/data/models/sensor_event_model.dart';

import '../../domain/entities/activity.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

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
          color: context.palette.textPrimary,
          letterSpacing: 0.3,
        );
    final now = DateTime.now();
    final dayQuery = StatsSummaryQuery(
      period: 'day',
      date: DateTime(now.year, now.month, now.day),
    );
    final dayStatsAsync = ref.watch(statsSummaryProvider(dayQuery));

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

    final sensorEvents =
        ref.watch(liveSensorEventsProvider).valueOrNull ?? const [];
    final latestSensorEvent = sensorEvents.isEmpty
        ? null
        : sensorEvents.reduce(
            (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
          );

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
      ActivityStatus.warning => const Color(0xFFEF4444),
      ActivityStatus.critical => const Color(0xFFEF4444),
    };
    // Trouve le jour le plus récent dans les données (suit la simulation,
    // pas DateTime.now() qui peut diverger de la date simulée).
    final lastActivity = observedForLastActivity.isEmpty
        ? null
        : observedForLastActivity.reduce(
            (a, b) => a.startAt.isAfter(b.startAt) ? a : b,
          );
    final latestDay = lastActivity == null
        ? null
        : lastActivity.startAt.toLocal();
    final latestDayStart = latestDay == null
        ? null
        : DateTime(latestDay.year, latestDay.month, latestDay.day);
    final latestDayActivities = latestDayStart == null
        ? <Activity>[]
        : observedForLastActivity.where((a) {
            final d = a.startAt.toLocal();
            return d.year == latestDayStart.year &&
                d.month == latestDayStart.month &&
                d.day == latestDayStart.day;
          }).toList();
    final lastActivityOfLatestDay = latestDayActivities.isEmpty
        ? null
        : latestDayActivities.reduce(
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
          // Deux colonnes uniquement en paysage (largeur > hauteur) ET tablette.
          final isWide = constraints.maxWidth >= 600 &&
              constraints.maxWidth > constraints.maxHeight;
          final avatarSize = isWide ? 96.0 : 72.0;
          final profileImagePath = ref.watch(profileImagePathProvider);
          final avatar = Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.surface,
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
                child: profileImagePath != null && File(profileImagePath).existsSync()
                    ? Image.file(
                        File(profileImagePath),
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/elderly_avatar.jpg',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          );

          final nameText = Text(
            ref.watch(watchedPersonNameProvider),
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          );

          final infoCard = Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.palette.textSecondary.withValues(alpha: 0.12),
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
                  label: 'Dernière sortie',
                  value: _formatLastActivityValue(lastActivityOfLatestDay),
                ),
                Divider(
                  height: 18,
                  thickness: 1,
                  color: context.palette.textSecondary.withValues(alpha: 0.10),
                ),
                _InfoTile(
                  icon: Icons.place_outlined,
                  iconColor: AppTheme.accentCyan,
                  label: 'Dernière localisation',
                  value: _formatLatestLocationValue(latestSensorEvent),
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
                    onPressed: () async {
                      final container = ProviderScope.containerOf(
                        context,
                        listen: false,
                      );
                      final anomalies = await container.read(
                        liveAnomaliesProvider.future,
                      );
                      final latestId = anomalies.isNotEmpty
                          ? anomalies.first.id
                          : null;
                      if (latestId != null) {
                        container
                            .read(focusedAnomalyIdProvider.notifier)
                            .state = latestId;
                      }
                      onNavigate?.call(2);
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

          // Phare responsive : occupe au max 80% de la largeur disponible,
          // plafonné à 320px, ratio 260/210 conservé.
          // Tablette portrait : jusqu'à 480px. Téléphone : plafonné à 320px.
          final phareWCap = constraints.maxWidth >= 600 ? 480.0 : 320.0;
          final phareMaxW = (constraints.maxWidth * 0.8).clamp(0.0, phareWCap);
          const phareAspect = 260.0 / 210.0;
          final phonePhare = buildPhare(
            width: phareMaxW,
            height: phareMaxW / phareAspect,
            lighthouseSize: (phareMaxW / phareAspect) * 0.9,
          );

          final summarySection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Résumé du jour', style: sectionLabelStyle),
              const SizedBox(height: 14),
              dayStatsAsync.when(
                data: (result) => _buildDailySummaryStatsFromBackend(
                  result.summary.sleepMinutes,
                  result.summary.mealsCount,
                  observedForLastActivity,
                ),
                loading: () => _buildDailySummaryStats(observedForLastActivity),
                error: (_, __) => _buildDailySummaryStats(observedForLastActivity),
              ),
            ],
          );

          if (isWide) {
            // Tablette paysage/portrait large : deux colonnes.
            // On contraint la hauteur via un padding + IntrinsicHeight est
            // trop coûteux — on utilise la hauteur réelle des contraintes.
            final availH = constraints.maxHeight - 48; // 24+24 padding
            const aspect = 260.0 / 210.0;
            final reserveBtn = hasLatestAnomaly ? 68.0 : 0.0;
            // Colonne droite = flex 6 sur largeur totale - 24 padding - 24 gap
            final rightColW = (constraints.maxWidth - 48 - 24) * 6 / 11;
            var phareW = rightColW;
            var phareH = phareW / aspect;
            final maxPhareH = availH - reserveBtn;
            if (phareH > maxPhareH) {
              phareH = maxPhareH;
              phareW = phareH * aspect;
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    child: Center(
                      child: buildPhare(
                        width: phareW,
                        height: phareH,
                        lighthouseSize: phareH * 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Téléphone / portrait tablette : layout vertical, scrollable.
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: summarySection,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getActivityColor(Activity activity) =>
      ActivityType.fromTypeContains(activity.type).color;

  Widget _buildDailySummaryStatsFromBackend(
    int sleepMinutes,
    int mealsCount,
    List<Activity> observed,
  ) {
    const expectedMeals = 3;
    final sleepHours = (sleepMinutes / 60).toStringAsFixed(1);
    final latestOther = observed.isEmpty
        ? null
        : observed
              .where((activity) {
                final t = ActivityType.fromTypeContains(activity.type);
                return !t.isSleep && !t.isMeal;
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
          value: '$mealsCount/$expectedMeals',
          icon: Icons.restaurant,
          color: AppTheme.activityPurple,
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
          value: latestOtherTime,
          icon: Icons.exit_to_app,
          color: AppTheme.accentBlue,
          flex: 1,
        ),
      ],
    );
  }

  /// Construire le résumé du jour avec des stats pertinentes (fallback local)
  Widget _buildDailySummaryStats(List<Activity> observed) {
    final dayStats = BehaviorStatsService.summarizeLatestDay(observed);
    const expectedMeals = 3;
    final sleepHours = (dayStats.sleepMinutes / 60).toStringAsFixed(1);
    final latestOther = observed.isEmpty
        ? null
        : observed
              .where((activity) {
                final t = ActivityType.fromTypeContains(activity.type);
                return !t.isSleep && !t.isMeal;
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
          color: AppTheme.activityPurple,
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

  void _showRealtimeAlertDialog(
    BuildContext context,
    WidgetRef ref,
    AlertItem alert,
    List<Activity> expected,
    List<Activity> observed,
  ) {
    final accentColor = AppTheme.activityRed;
    final textTheme = Theme.of(context).textTheme;
    final typeLabel = _anomalyLabel(alert.anomalyType);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final maxW = constraints.maxWidth.clamp(0, 420).toDouble();
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.18),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.78),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          child: Text(
                            typeLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  (textTheme.headlineSmall?.fontSize ?? 24) +
                                  2,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _humanizeAlertDescription(alert),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.palette.textPrimary,
                                  fontSize:
                                      textTheme.bodyMedium?.fontSize ?? 14,
                                  height: 1.45,
                                ),
                              ),
                              if (_extractAlertMetrics(alert) != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _extractAlertMetrics(alert)!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 190,
                                child: PhareMagnifique(
                                  expected: expected,
                                  observed: observed,
                                  alertSeverity: alert.severity,
                                  forceGyrophare: true,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
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
                                              .read(
                                                focusedAnomalyIdProvider
                                                    .notifier,
                                              )
                                              .state =
                                          latestId;
                                    }
                                    onNavigate?.call(2);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Voir l'anomalie",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _anomalyLabel(String anomalyType) =>
      AnomalyType.fromKey(anomalyType).label;

  String _humanizeAlertDescription(AlertItem alert) {
    final activity = _extractActivityName(alert);
    return _phraseFor(alert.anomalyType, activity);
  }

  /// Extrait les valeurs techniques (ratio, score…) du message brut
  /// backend, sous forme courte et lisible. Renvoie null si rien d'utile.
  String? _extractAlertMetrics(AlertItem alert) {
    final raw = alert.description;
    final paren = RegExp(r'\(([^)]+)\)').firstMatch(raw)?.group(1)?.trim();
    if (paren == null || paren.isEmpty) return null;
    // ratio: 2.3 vs normal: 1.0  ->  2.3× la durée habituelle
    final ratioVs = RegExp(
      r'ratio\s*[:=]\s*([\d.]+)\s*vs\s*normal\s*[:=]\s*([\d.]+)',
      caseSensitive: false,
    ).firstMatch(paren);
    if (ratioVs != null) {
      final r = double.tryParse(ratioVs.group(1) ?? '');
      if (r != null) {
        final pct = ((r - 1) * 100).round();
        if (r > 1) return '+$pct % par rapport à la moyenne';
        if (r < 1) return '$pct % par rapport à la moyenne';
      }
    }
    // score de similarité temporelle: 0.12  ->  Similarité 12 %
    final score = RegExp(
      r'(?:score\s+de\s+)?similarit[ée][^:=]*[:=]\s*([\d.]+)',
      caseSensitive: false,
    ).firstMatch(paren);
    if (score != null) {
      final s = double.tryParse(score.group(1) ?? '');
      if (s != null) return 'Similarité ${(s * 100).round()} %';
    }
    // ratio simple
    final ratio = RegExp(
      r'ratio\s*[:=]\s*([\d.]+)',
      caseSensitive: false,
    ).firstMatch(paren);
    if (ratio != null) {
      final r = double.tryParse(ratio.group(1) ?? '');
      if (r != null) return 'Ratio ${r.toStringAsFixed(1)}×';
    }
    return paren;
  }

  String? _extractActivityName(AlertItem alert) {
    final source = '${alert.description} ${alert.title}'.toLowerCase();
    final t = ActivityType.fromTypeContains(source);
    return t == ActivityType.unknown ? null : t.subject;
  }

  String _phraseFor(String anomalyType, String? activity) =>
      AnomalyType.fromKey(anomalyType).phraseFor(activity);

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
    final local = activity.startAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${activityTypeLabel(activity.type)} • $time';
  }

  String _formatLatestLocationValue(SensorEventModel? event) {
    if (event == null) return 'Inconnue';
    final time =
        '${event.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${event.timestamp.toLocal().minute.toString().padLeft(2, '0')}';
    return '${roomLabel(event.room)} • $time';
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
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w500,
        );
    final statValueStyle =
        appTypography?.statValue ??
        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color);

    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.palette.textSecondary.withValues(alpha: 0.12),
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
              style: statValueStyle.copyWith(color: context.palette.textPrimary),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activity.startAt.hour.toString().padLeft(2, '0')}:${activity.startAt.minute.toString().padLeft(2, '0')} - ${activity.endAt?.hour.toString().padLeft(2, '0') ?? '--'}:${activity.endAt?.minute.toString().padLeft(2, '0') ?? '--'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textSecondary,
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
                  color: context.palette.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: context.palette.textPrimary,
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
