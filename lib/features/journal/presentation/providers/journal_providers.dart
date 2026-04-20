import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/home/domain/entities/activity.dart';

// Placeholder — la journée type vient du backend uniquement
final expectedActivitiesProvider = Provider<List<Activity>>((ref) => const []);

// Placeholder — les activités observées viennent du backend via liveObservedActivitiesProvider
final observedActivitiesProvider = Provider<List<Activity>>((ref) => const []);
