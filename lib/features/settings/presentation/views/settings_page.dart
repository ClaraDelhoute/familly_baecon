import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/providers/accessibility_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/services/settings_service.dart';
import 'package:familly_baecon/core/models/absence_period.dart';
import 'package:familly_baecon/features/home/presentation/providers/test_mode_provider.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/profile/presentation/widgets/profile_avatar_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _settings = SettingsService();
  AbsencePeriod _absence = AbsencePeriod();
  bool _isAbsenceActive = false;

  @override
  void initState() {
    super.initState();
    _loadAbsence();
  }

  Future<void> _loadAbsence() async {
    final p = await _settings.loadAbsencePeriod();
    if (mounted) {
      setState(() {
        _absence = p;
        _isAbsenceActive = p.isDefined;
      });
    }
  }

  Future<void> _onToggleAbsence(bool value) async {
    if (!value) {
      await _settings.saveAbsencePeriod(AbsencePeriod());
      if (mounted) {
        setState(() {
          _absence = AbsencePeriod();
          _isAbsenceActive = false;
        });
      }
      return;
    }

    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime(now.year + 5),
      helpText: 'Date de début d\'absence',
    );
    if (start == null) return;

    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 1)),
      firstDate: start,
      lastDate: DateTime(now.year + 5),
      helpText: 'Date de fin d\'absence',
    );
    if (end == null) return;

    final period = AbsencePeriod(start: start, end: end);
    await _settings.saveAbsencePeriod(period);
    if (mounted) {
      setState(() {
        _absence = period;
        _isAbsenceActive = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverConnected =
        ref.watch(backendApiConnectedProvider) ||
        ref.watch(backendMqttConnectedProvider);
    final lastSyncAt = ref.watch(backendLastSyncAtProvider);
    final forceSync = ref.watch(forceBackendSyncProvider);
    final testMode = ref.watch(testModeProvider);
    final accessibility = ref.watch(accessibilitySettingsProvider);
    final accessibilityNotifier = ref.read(
      accessibilitySettingsProvider.notifier,
    );
    final iconSize = Theme.of(context).iconTheme.size ?? 24;
    final appTypography = Theme.of(context).extension<AppTypography>();
    final sectionTitleStyle =
        appTypography?.sectionLabel.copyWith(color: AppTheme.textSecondary) ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === PHOTO DE PROFIL ===
          Text('Photo de profil', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const ProfileAvatarWidget(size: 70, initialName: 'R'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier la photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appuyez sur la photo pour la changer',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // === SERVEUR ===
          Text('Connexion', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.circle,
                size: (iconSize * 0.5).clamp(12, 20),
                color: serverConnected
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              title: Text(
                'Serveur ${serverConnected ? 'disponible' : 'indisponible'}',
              ),
              subtitle: Text(
                'Mise à jour: ${lastSyncAt == null ? '--:--:--' : _formatHms(lastSyncAt)}',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Plage d\'absence', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.event_busy, size: iconSize, color: AppTheme.activityOrange),
                  title: const Text('Mode Absence'),
                  subtitle: const Text('Désactiver le suivi et les notifications'),
                  value: _isAbsenceActive,
                  onChanged: _onToggleAbsence,
                ),
                if (_isAbsenceActive && _absence.start != null && _absence.end != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Début',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_absence.start!.day.toString().padLeft(2, '0')}/${_absence.start!.month.toString().padLeft(2, '0')}/${_absence.start!.year}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Fin',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_absence.end!.day.toString().padLeft(2, '0')}/${_absence.end!.month.toString().padLeft(2, '0')}/${_absence.end!.year}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await forceSync();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mise à jour terminée')),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible de mettre à jour'),
                    ),
                  );
                }
              },
              icon: Icon(Icons.refresh_rounded, size: iconSize),
              label: const Text('Reconnexion / mise à jour serveur'),
            ),
          ),
          const SizedBox(height: 20),
          Text('Accessibilité', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Contraste renforcé'),
                    subtitle: const Text(
                      'Améliore la lisibilité des textes et des contours',
                    ),
                    value: accessibility.highContrast,
                    onChanged: (value) {
                      accessibilityNotifier.setHighContrast(value);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.text_fields, size: iconSize),
                    title: const Text('Taille du texte'),
                    subtitle: Text(
                      '${(accessibility.textScaleFactor * 100).round()}%',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: accessibility.textScaleFactor,
                      min: 0.8,
                      max: 1.6,
                      divisions: 8,
                      label:
                          '${(accessibility.textScaleFactor * 100).round()}%',
                      onChanged: (value) {
                        accessibilityNotifier.setTextScaleFactor(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.touch_app, size: iconSize),
                    title: const Text('Taille des icônes'),
                    subtitle: Text(
                      '${(accessibility.iconScaleFactor * 100).round()}%',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: accessibility.iconScaleFactor,
                      min: 0.8,
                      max: 1.8,
                      divisions: 10,
                      label:
                          '${(accessibility.iconScaleFactor * 100).round()}%',
                      onChanged: (value) {
                        accessibilityNotifier.setIconScaleFactor(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Débug anomalies', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<TestMode>(
              groupValue: testMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(testModeProvider.notifier).state = mode;
                }
              },
              child: const Column(
                children: [
                  RadioListTile<TestMode>(
                    value: TestMode.real,
                    title: Text('🔄 Réel'),
                  ),
                  RadioListTile<TestMode>(
                    value: TestMode.ok,
                    title: Text('🟢 OK'),
                  ),
                  RadioListTile<TestMode>(
                    value: TestMode.warning,
                    title: Text('🟡 Warning'),
                  ),
                  RadioListTile<TestMode>(
                    value: TestMode.critical,
                    title: Text('🔴 Critical'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHms(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }
}
