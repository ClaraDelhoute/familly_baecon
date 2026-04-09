import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/presentation/providers/anomaly_focus_provider.dart';
import 'package:familly_baecon/features/anomalies/presentation/views/anomaly_detail_page.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';

class AnomaliesPage extends ConsumerWidget {
  const AnomaliesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(liveAnomaliesProvider);
    final focusedId = ref.watch(focusedAnomalyIdProvider);
    final anomalies = [...(anomaliesAsync.valueOrNull ?? const [])];

    if (focusedId != null && anomalies.isNotEmpty) {
      final index = anomalies.indexWhere((item) => item.id == focusedId);
      if (index > 0) {
        final focused = anomalies.removeAt(index);
        anomalies.insert(0, focused);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Anomalies')),
      body: anomalies.isEmpty
          ? Center(
              child: Text(
                'Aucune anomalie',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              itemCount: anomalies.length,
              itemBuilder: (context, index) {
                final anomaly = anomalies[index];
                final repeated = anomaly.seenCount > 1;
                final isHigh = anomaly.severity == 'high';
                return ListTile(
                  leading: Icon(
                    isHigh
                        ? Icons.priority_high_rounded
                        : (repeated ? Icons.repeat : Icons.fiber_new),
                    color: isHigh
                        ? AppTheme.activityRed
                        : (repeated ? AppTheme.activityOrange : AppTheme.activityGreen),
                  ),
                  title: Text(
                    anomaly.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_typeLabel(anomaly.anomalyType)} • ${_severityLabel(anomaly.severity)} • ${_fmtDate(anomaly.detectedDate)} • vues: ${anomaly.seenCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _fmtTimeFrance(anomaly.simulatedAt),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnomalyDetailPage(anomaly: anomaly),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _fmtDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  String _fmtTimeFrance(DateTime date) {
    final franceTime = _toFranceTime(date);
    return '${franceTime.hour.toString().padLeft(2, '0')}:${franceTime.minute.toString().padLeft(2, '0')}';
  }

  DateTime _toFranceTime(DateTime date) {
    final utc = date.toUtc();
    final isDst = _isFranceDst(utc);
    final offsetHours = isDst ? 2 : 1;
    return utc.add(Duration(hours: offsetHours));
  }

  bool _isFranceDst(DateTime utc) {
    final start = _lastSundayUtc(utc.year, 3).add(const Duration(hours: 1));
    final end = _lastSundayUtc(utc.year, 10).add(const Duration(hours: 1));
    return utc.isAfter(start) && utc.isBefore(end);
  }

  DateTime _lastSundayUtc(int year, int month) {
    final firstNextMonth = month == 12
        ? DateTime.utc(year + 1, 1, 1)
        : DateTime.utc(year, month + 1, 1);
    final lastDayOfMonth = firstNextMonth.subtract(const Duration(days: 1));
    return lastDayOfMonth.subtract(Duration(days: lastDayOfMonth.weekday % 7));
  }

  String _severityLabel(String severity) {
    return switch (severity.toLowerCase()) {
      'high' => 'Gravité élevée',
      'medium' => 'Gravité moyenne',
      _ => 'Gravité moyenne',
    };
  }

  String _typeLabel(String type) {
    return switch (type.toLowerCase()) {
      'missing' => 'Activité manquante',
      'timing' => 'Horaire inhabituel',
      'duration_short' => 'Durée trop courte',
      'duration_long' => 'Durée trop longue',
      'freq_high' => 'Fréquence trop élevée',
      'freq_low' => 'Fréquence trop faible',
      _ => 'Anomalie',
    };
  }
}
