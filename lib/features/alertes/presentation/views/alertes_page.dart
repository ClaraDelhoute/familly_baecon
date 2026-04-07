import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class AlertesPage extends StatelessWidget {
  const AlertesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Données factices d'alertes
    final alerts = [
      {
        'title': 'Activité inhabituelle',
        'description': 'L\'activité "Ordinateur" a dépassé 2h30',
        'severity': 'warning',
        'time': 'Il y a 15 min',
      },
      {
        'title': 'Absence détectée',
        'description': 'Aucune activité depuis 45 minutes',
        'severity': 'error',
        'time': 'Il y a 10 min',
      },
      {
        'title': 'Retour à la normale',
        'description': 'Activité "Cuisine" détectée',
        'severity': 'success',
        'time': 'Il y a 5 min',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes & Notifications'),
        elevation: 0,
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final color = alert['severity'] == 'error'
                    ? AppTheme.activityRed
                    : alert['severity'] == 'warning'
                        ? AppTheme.activityOrange
                        : AppTheme.activityGreen;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 70,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      alert['severity'] == 'error'
                                          ? Icons.warning_rounded
                                          : alert['severity'] == 'warning'
                                              ? Icons.info
                                              : Icons.check_circle,
                                      color: color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        alert['title'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert['description'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert['time'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 18,
                            onPressed: () {},
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

