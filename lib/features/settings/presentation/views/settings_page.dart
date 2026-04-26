import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/providers/accessibility_provider.dart';
import 'package:familly_baecon/core/providers/theme_mode_provider.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/core/services/settings_service.dart';
import 'package:familly_baecon/core/models/absence_period.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';
import 'package:familly_baecon/features/profile/presentation/widgets/profile_avatar_widget.dart';
import 'package:familly_baecon/core/theme/palette_x.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final SettingsService _settings;
  AbsencePeriod _absence = AbsencePeriod();
  bool _isAbsenceActive = false;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(settingsServiceProvider);
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
    final accessibility = ref.watch(accessibilitySettingsProvider);
    final accessibilityNotifier = ref.read(
      accessibilitySettingsProvider.notifier,
    );
    final themeMode = ref.watch(themeModeProvider);
    // Taille d'icône fixe pour la page Paramètres (ne suit pas les réglages
    // utilisateur, hormis les deux icônes de prévisualisation des sliders).
    const double iconSize = 24;
    // Icônes de prévisualisation : reflètent la taille choisie par l'utilisateur.
    final double previewIconSize = 24 * accessibility.iconScaleFactor;
    final double previewTextFontSize = 16 * accessibility.textScaleFactor;
    final appTypography = Theme.of(context).extension<AppTypography>();
    final sectionTitleStyle =
        appTypography?.sectionLabel.copyWith(color: context.palette.textSecondary) ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w700,
        );

    final mediaQuery = MediaQuery.of(context);
    // Neutralise le textScaleFactor utilisateur sur la page Paramètres en
    // remettant uniquement le multiplicateur de base de l'app.
    final fixedMediaQuery = mediaQuery.copyWith(
      textScaler: TextScaler.linear(AppTheme.baseTextScaleMultiplier),
    );
    // Thème figé : ignore les facteurs utilisateur (texte et icônes) pour que
    // la page Paramètres reste stable, AppBar comprise.
    final fixedTheme = AppTheme.buildTheme(
      textScaleFactor: 1.0,
      iconScaleFactor: 1.0,
    );

    return Theme(
      data: fixedTheme,
      child: MediaQuery(
        data: fixedMediaQuery,
        child: Scaffold(
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
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appuyez sur la photo pour la changer',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.palette.textSecondary,
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
                size: 12,
                color: serverConnected
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
              title: Text(
                'Serveur ${serverConnected ? 'disponible' : 'indisponible'}',
              ),
              subtitle: Text(
                'Mise à jour: ${lastSyncAt == null ? '--:--:--' : _formatHms(lastSyncAt)}',
              ),
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
          Text('Plage d\'absence', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.event_busy, size: iconSize, color: AppTheme.accentCyan),
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
                                style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
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
                                style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
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
          const SizedBox(height: 20),
          Text('Apparence', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                themeMode == AppThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                size: iconSize,
                color: AppTheme.accentCyan,
              ),
              title: const Text('Mode sombre'),
              subtitle: const Text(
                'Bascule entre le thème clair et le thème sombre',
              ),
              value: themeMode == AppThemeMode.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setMode(
                      value ? AppThemeMode.dark : AppThemeMode.light,
                    );
              },
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
                  ListTile(
                    leading: const Icon(Icons.text_fields, size: iconSize),
                    title: const Text('Taille du texte'),
                    subtitle: Text(
                      '${(accessibility.textScaleFactor * 100).round()}%',
                    ),
                    minVerticalPadding: 12,
                    trailing: SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: previewTextFontSize,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ),
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
                    leading: const Icon(Icons.touch_app, size: iconSize),
                    title: const Text('Taille des icônes'),
                    subtitle: Text(
                      '${(accessibility.iconScaleFactor * 100).round()}%',
                    ),
                    minVerticalPadding: 12,
                    trailing: SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: Icon(
                          Icons.star_rounded,
                          size: previewIconSize,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: accessibility.iconScaleFactor.clamp(0.8, 1.3),
                      min: 0.8,
                      max: 1.3,
                      divisions: 5,
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
        ],
      ),
        ),
      ),
    );
  }

  String _formatHms(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }
}
