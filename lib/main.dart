import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:familly_baecon/core/utils/orientation_lock.dart';
import 'package:familly_baecon/core/providers/accessibility_provider.dart';
import 'package:familly_baecon/core/providers/theme_mode_provider.dart';
import 'package:familly_baecon/core/services/app_badge_service.dart';
import 'package:familly_baecon/core/services/anomaly_notification_service.dart';
import 'package:familly_baecon/core/services/fcm_push_service.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_focus_provider.dart';
import 'package:familly_baecon/features/home/presentation/providers/test_mode_provider.dart';
import 'package:familly_baecon/features/home/presentation/views/home_page.dart';
import 'package:familly_baecon/features/home/presentation/widgets/alert_bubbles_widget.dart';
import 'package:familly_baecon/features/home/presentation/widgets/phare_magnifique.dart';
import 'package:familly_baecon/features/journal/data/models/routine_activity_model.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/journal/presentation/views/journal_page.dart';
import 'package:familly_baecon/features/analyse/presentation/views/analyse_page.dart';
import 'package:familly_baecon/features/anomalies/presentation/views/anomalies_page.dart';
import 'package:familly_baecon/features/plan/presentation/views/plan_page.dart';
import 'package:familly_baecon/core/domain/activity_type.dart';
import 'package:familly_baecon/core/domain/anomaly_type.dart';
import 'package:familly_baecon/features/splash/presentation/views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await applyDefaultOrientationLock();
  await AppBadgeService.initialize();
  runApp(const ProviderScope(child: MyApp()));
  unawaited(AnomalyNotificationService.initialize());
  if (!kIsWeb && !kDebugMode) {
    unawaited(FcmPushService.initialize());
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilitySettingsProvider);
    // Déclenche le rebuild quand le mode change ; AppTheme.applyMode est déjà
    // appelé par le notifier, donc buildTheme lit les bonnes couleurs.
    ref.watch(themeModeProvider);
    final globalTextScale =
        accessibility.textScaleFactor * AppTheme.baseTextScaleMultiplier;
    final theme = AppTheme.buildTheme(
      textScaleFactor: accessibility.textScaleFactor,
      iconScaleFactor: accessibility.iconScaleFactor,
    );

    return MaterialApp(
      title: 'FamilyBeacon',
      theme: theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      // Suit la langue de l'appareil quand elle est supportée, sinon français.
      localeListResolutionCallback: (locales, supported) {
        if (locales != null) {
          for (final l in locales) {
            for (final s in supported) {
              if (s.languageCode == l.languageCode) return s;
            }
          }
        }
        return const Locale('fr');
      },
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(globalTextScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
      routes: {'/home': (context) => const FamilyBeaconApp()},
      debugShowCheckedModeBanner: false,
    );
  }
}

class FamilyBeaconApp extends ConsumerStatefulWidget {
  const FamilyBeaconApp({super.key});

  @override
  ConsumerState<FamilyBeaconApp> createState() => _FamilyBeaconAppState();
}

class _FamilyBeaconAppState extends ConsumerState<FamilyBeaconApp> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomePage(onNavigate: _navigateTo),
    const JournalPage(),
    const AnomaliesPage(),
    const PlanPage(),
    const AnalysePage(),
  ];

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Le listener est enregistré dans build via ref.listen (pattern Riverpod)
  }

  String _fmt(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }

  String _expectedFromRoutine(List<RoutineActivityModel> routine, AnomalyHistoryModel anomaly) {
    final sensorType = anomaly.activityKey;
    if (sensorType.isEmpty) return '—';

    final targetSensor = sensorType == 'daily_activity' ? 'activity_profile' : sensorType;

    RoutineActivityModel? entry;
    try {
      entry = routine.firstWhere(
        (r) => r.sensorType.toLowerCase() == targetSensor.toLowerCase(),
      );
    } catch (_) {}

    if (entry == null) return '—';
    final isSleep = sensorType.toLowerCase() == 'sleep';
    // sleep : observé = heure réveil, attendu = heure réveil habituelle (endLabel)
    // autres : timing/duration → heure fin habituelle, sinon heure début
    final isEndLabel = isSleep ||
        anomaly.anomalyType == 'timing' ||
        anomaly.anomalyType == 'duration_long' ||
        anomaly.anomalyType == 'duration_short';
    final timeLabel = isEndLabel ? entry.endLabel : entry.startLabel;
    return timeLabel.isNotEmpty ? timeLabel : '—';
  }

  Future<void> _showAnomalyDialog(AnomalyHistoryModel anomaly) async {
    final accentColor = AppTheme.activityRed;
    final textTheme = Theme.of(context).textTheme;
    final typeLabel = AnomalyType.fromKey(anomaly.anomalyType).label;

    final observedLabel = _fmt(anomaly.simulatedAt);

    final routine = await ref.read(liveRoutineProvider.future).catchError((_) => <RoutineActivityModel>[]);
    if (!mounted) return;
    final expectedLabel = _expectedFromRoutine(routine, anomaly);

    final observed = ref.read(testObservedActivitiesProvider);
    final expected = ref.read(testExpectedActivitiesProvider);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final maxW = constraints.maxWidth.clamp(0, 420).toDouble();
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                              fontSize: (textTheme.headlineSmall?.fontSize ?? 24) + 2,
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
                                AnomalyType.fromKey(anomaly.anomalyType).phraseFor(
                                  _activitySubject(anomaly),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: textTheme.bodyMedium?.fontSize ?? 14,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AlertObservedExpectedBubbles(
                                observedLabel: observedLabel,
                                expectedLabel: expectedLabel,
                                accentColor: accentColor,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 190,
                                child: PhareMagnifique(
                                  expected: expected,
                                  observed: observed,
                                  alertSeverity: anomaly.severity,
                                  forceGyrophare: true,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    ref.read(focusedAnomalyIdProvider.notifier).state = anomaly.id;
                                    _navigateTo(2);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  String? _activitySubject(AnomalyHistoryModel anomaly) {
    final t = ActivityType.fromKey(anomaly.activityKey);
    if (t != ActivityType.unknown) return t.subject;
    final source = anomaly.message.toLowerCase();
    final t2 = ActivityType.fromTypeContains(source);
    return t2 == ActivityType.unknown ? null : t2.subject;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(liveAnomaliesProvider, (previous, next) {
      final anomalies = next.valueOrNull;
      if (anomalies == null || anomalies.isEmpty) return;
      final latest = anomalies.first;
      final lastShown = ref.read(lastPopupAnomalyIdProvider);
      if (latest.id == lastShown) return;
      // Vérifier que c'est une anomalie absente de la liste précédente
      final prevIds = previous?.valueOrNull?.map((a) => a.id).toSet() ?? {};
      final isNewAnomaly = !prevIds.contains(latest.id);
      if (!isNewAnomaly) return;
      ref.read(lastPopupAnomalyIdProvider.notifier).state = latest.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showAnomalyDialog(latest);
      });
    });

    final iconSize = Theme.of(context).iconTheme.size ?? 24;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.0,
        child: NavigationBarTheme(
          data: Theme.of(context).navigationBarTheme.copyWith(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final base =
                  Theme.of(
                    context,
                  ).navigationBarTheme.labelTextStyle?.resolve(states) ??
                  const TextStyle();
              return base.copyWith(
                fontSize: 11,
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home, size: iconSize),
                label: 'Résumé',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today, size: iconSize),
                label: 'Activités',
              ),
              NavigationDestination(
                icon: Icon(Icons.warning_amber_rounded, size: iconSize),
                label: 'Anomalies',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined, size: iconSize),
                label: 'Localisation',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart, size: iconSize),
                label: 'Stats',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
