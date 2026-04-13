import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';
import 'package:familly_baecon/features/home/presentation/providers/test_mode_provider.dart';
import 'package:familly_baecon/features/journal/presentation/providers/backend_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverConnected =
        ref.watch(backendApiConnectedProvider) ||
        ref.watch(backendMqttConnectedProvider);
    final lastSyncAt = ref.watch(backendLastSyncAtProvider);
    final forceSync = ref.watch(forceBackendSyncProvider);
    final testMode = ref.watch(testModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.circle,
                size: 12,
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
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reconnexion / mise à jour serveur'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Débug anomalies',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
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
