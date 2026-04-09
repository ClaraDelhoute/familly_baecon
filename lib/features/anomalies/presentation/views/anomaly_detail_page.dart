import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/anomalies/data/models/anomaly_history_model.dart';

class AnomalyDetailPage extends StatelessWidget {
  final AnomalyHistoryModel anomaly;

  const AnomalyDetailPage({
    super.key,
    required this.anomaly,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail anomalie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _field('Type', _typeLabel(anomaly.anomalyType)),
                _field('Gravité', _severityLabel(anomaly.severity)),
                _field('Activity key', anomaly.activityKey),
                _field('Date détectée', _fmtDate(anomaly.detectedDate)),
                _field('Heure simulée', _fmtDateTime(anomaly.simulatedAt)),
                _field('Première détection (système)', _fmtDateTime(anomaly.firstDetectedAt)),
                _field('Dernière vue (système)', _fmtDateTime(anomaly.lastSeenAt)),
                _field('Répétitions', anomaly.seenCount.toString()),
                const SizedBox(height: 16),
                Text(
                  _explanationByType(anomaly.anomalyType),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _fmtDateTime(DateTime dateTime) {
    final franceTime = _toFranceTime(dateTime);
    final d = _fmtDate(franceTime);
    final h = franceTime.hour.toString().padLeft(2, '0');
    final m = franceTime.minute.toString().padLeft(2, '0');
    return '$d $h:$m';
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

  String _explanationByType(String type) {
    switch (type.toLowerCase()) {
      case 'missing':
        return 'Activité attendue dans la journée type mais non observée.';
      case 'timing':
        return 'Activité observée à un horaire différent de la routine habituelle.';
      case 'duration_short':
        return 'Activité observée mais plus courte que d’habitude.';
      case 'duration_long':
        return 'Activité observée mais plus longue que d’habitude.';
      case 'freq_high':
        return 'Activité observée plus fréquemment que la routine habituelle.';
      case 'freq_low':
        return 'Activité observée moins fréquemment que la routine habituelle.';
      default:
        return 'Anomalie détectée par comparaison avec la journée type.';
    }
  }

  String _severityLabel(String severity) {
    return switch (severity.toLowerCase()) {
      'high' => 'Élevée',
      'medium' => 'Moyenne',
      _ => 'Moyenne',
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
