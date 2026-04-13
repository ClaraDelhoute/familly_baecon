import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyBeacon',
      theme: AppTheme.darkTheme,
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
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Anomalies',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Analyse'),
        ],
      ),
    );
  }
}
