import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/features/journal/presentation/providers/journal_providers.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/calendar_timeline.dart';
import 'package:familly_baecon/features/journal/presentation/widgets/floorplan_modal.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/widgets/common_header.dart';

class JournalPage extends ConsumerWidget {
  final Function(int)? onNavigate;

  const JournalPage({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expected = ref.watch(expectedActivitiesProvider);
    final observed = ref.watch(observedActivitiesProvider);

    // Obtenir la date actuelle
    final now = DateTime.now();
    final dateFormatter = '${now.day.toString().padLeft(2, '0')} ${['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'][now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Column(
        children: [
          // Common Header
          CommonHeader(
            title: 'Journal du jour',
            subtitle: dateFormatter,
            // actionWidget supprimé - pas de bouton de localisation
          ),
          // Légende des couleurs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.darkBgLight.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('🟢 Correspond', AppTheme.activityGreen),
                _buildLegendItem('🔴 Ne correspond pas', AppTheme.activityRed),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Timeline
          Expanded(
            child: CalendarTimeline(
              expectedActivities: expected,
              observedActivities: observed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

