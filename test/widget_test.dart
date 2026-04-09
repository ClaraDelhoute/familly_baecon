import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:familly_baecon/features/splash/presentation/views/splash_screen.dart';

void main() {
  testWidgets('Splash navigates to home route after delay', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Fake Home')),
        },
      ),
    );

    expect(find.text('FamilyBeacon'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Fake Home'), findsOneWidget);
  });
}
