import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class AlertesPage extends ConsumerWidget {
  const AlertesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(liveAlertsProvider);
    final alerts = alertsAsync.valueOrNull ?? const [];

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
                    color: context.palette.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte',
                    style: TextStyle(
                      color: context.palette.textSecondary,
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
                final isHigh = alert.severity == 'high';
                final color = AppTheme.activityRed;

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
                                      isHigh ? Icons.priority_high_rounded : Icons.warning_amber_rounded,
                                      color: color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${alert.title} • ${isHigh ? 'Priorité haute' : 'Priorité moyenne'}',
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
                                  alert.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.palette.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _relativeTime(alert.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.palette.textSecondary.withValues(alpha: 0.7),
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
                            color: context.palette.textSecondary,
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

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'À l’instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}

