import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/splash/presentation/views/splash_screen.dart';
import 'package:familly_baecon/features/home/presentation/views/home_page.dart';
import 'package:familly_baecon/features/journal/presentation/views/journal_page.dart';
import 'package:familly_baecon/features/analyse/presentation/views/analyse_page.dart';
import 'package:familly_baecon/features/anomalies/presentation/views/anomalies_page.dart';

void main() {
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
      routes: {
        '/home': (context) => const FamilyBeaconApp(),
      },
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
    const AnalysePage(),
    const AnomaliesPage(),
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
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Analyse',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Anomalies',
          ),
        ],
      ),
    );
  }
}
