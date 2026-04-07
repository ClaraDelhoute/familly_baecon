import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entité pour tracker les anomalies vues par l'utilisateur
class AnomalyTracker {
  final Set<String> viewedAnomalies;
  final DateTime? lastCriticalAnomalyTime;

  AnomalyTracker({
    this.viewedAnomalies = const {},
    this.lastCriticalAnomalyTime,
  });

  AnomalyTracker copyWith({
    Set<String>? viewedAnomalies,
    DateTime? lastCriticalAnomalyTime,
  }) {
    return AnomalyTracker(
      viewedAnomalies: viewedAnomalies ?? this.viewedAnomalies,
      lastCriticalAnomalyTime: lastCriticalAnomalyTime ?? this.lastCriticalAnomalyTime,
    );
  }

  bool hasViewedAnomaly(String anomalyId) => viewedAnomalies.contains(anomalyId);

  AnomalyTracker markAnomalyAsViewed(String anomalyId) {
    return copyWith(
      viewedAnomalies: {...viewedAnomalies, anomalyId},
    );
  }
}

/// Provider pour tracker l'état des anomalies vues
final anomalyTrackerProvider = StateProvider<AnomalyTracker>((ref) {
  return AnomalyTracker();
});

