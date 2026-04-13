import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TestMode { real, ok, warning, critical }

final testModeProvider = StateProvider<TestMode>((ref) => TestMode.real);
final lastPopupAlertIdProvider = StateProvider<String?>((ref) => null);
