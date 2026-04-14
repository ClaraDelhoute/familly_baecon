import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/providers/accessibility_provider.dart';
import 'package:familly_baecon/core/services/app_badge_service.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/splash/presentation/views/splash_screen.dart';
import 'package:familly_baecon/features/home/presentation/views/home_page.dart';
import 'package:familly_baecon/features/journal/presentation/views/journal_page.dart';
import 'package:familly_baecon/features/analyse/presentation/views/analyse_page.dart';
import 'package:familly_baecon/features/anomalies/presentation/views/anomalies_page.dart';
import 'package:familly_baecon/features/plan/presentation/views/plan_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBadgeService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilitySettingsProvider);
    final globalTextScale =
        accessibility.textScaleFactor * AppTheme.baseTextScaleMultiplier;
    final theme = AppTheme.buildTheme(
      textScaleFactor: accessibility.textScaleFactor,
      iconScaleFactor: accessibility.iconScaleFactor,
      highContrast: accessibility.highContrast,
    );

    return MaterialApp(
      title: 'FamilyBeacon',
      theme: theme,
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

class FamilyBeaconApp extends StatefulWidget {
  const FamilyBeaconApp({super.key});

  @override
  State<FamilyBeaconApp> createState() => _FamilyBeaconAppState();
}

class _FamilyBeaconAppState extends State<FamilyBeaconApp> {
  int _selectedIndex = 0; // Accueil par défaut

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
  Widget build(BuildContext context) {
    final iconSize = Theme.of(context).iconTheme.size ?? 24;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
