import 'package:flutter/material.dart';
import 'package:familly_baecon/core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // États des paramètres
  bool isOnVacation = false;
  bool notificationsEnabled = true;
  bool locationTrackingEnabled = true;
  bool alertsEnabled = true;
  bool dataCollectionEnabled = true;

  // Sélection du mode thème
  String selectedTheme = 'auto'; // light, dark, auto

  @override
  Widget build(BuildContext context) {
    // Déterminer le thème actuel
    final isDarkMode = selectedTheme == 'dark' ||
        (selectedTheme == 'auto' && MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Couleurs adaptées au thème
    final bgColor = isDarkMode ? AppTheme.darkBg : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Profil & Paramètres'),
        elevation: 0,
        backgroundColor: bgColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === HEADER PROFIL - FULL WIDTH ===
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accentBlue, AppTheme.accentCyan],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nom
                  const Text(
                    'René Martin',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info
                  Text(
                    'Né le 15 Janvier 1958',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ID: RE-2024-001',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // === SECTIONS DE PARAMÈTRES ===
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STATUT & SUIVI ---
                  _buildSectionTitle('Suivi & Statut', isDarkMode),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.event_busy,
                    title: 'Mode Absence',
                    subtitle: 'Désactiver le suivi (vacances, hôpital, voyage...)',
                    value: isOnVacation,
                    onChanged: (value) {
                      setState(() => isOnVacation = value);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.location_on,
                    title: 'Suivi de localisation',
                    subtitle: 'Activer le suivi GPS en temps réel',
                    value: locationTrackingEnabled,
                    onChanged: (value) {
                      setState(() => locationTrackingEnabled = value);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 24),

                  // --- NOTIFICATIONS ---
                  _buildSectionTitle('Notifications', isDarkMode),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Recevoir les alertes et mises à jour',
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() => notificationsEnabled = value);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.warning,
                    title: 'Alertes anomalies',
                    subtitle: 'Alerter en cas d\'activité inhabituelle',
                    value: alertsEnabled,
                    onChanged: (value) {
                      setState(() => alertsEnabled = value);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 24),

                  // --- CONFIDENTIALITÉ & DONNÉES ---
                  _buildSectionTitle('Confidentialité & Données', isDarkMode),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.data_usage,
                    title: 'Collecte de données',
                    subtitle: 'Permettre la collecte pour améliorer le service',
                    value: dataCollectionEnabled,
                    onChanged: (value) {
                      setState(() => dataCollectionEnabled = value);
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildExpandableCard(
                    title: 'Stockage des données',
                    icon: Icons.storage,
                    content: 'Données stockées: 2.4 MB\nDernière sauvegarde: Aujourd\'hui 14:32\nEspace disponible: 48 GB',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 24),

                  // --- APPARENCE ---
                  _buildSectionTitle('Apparence', isDarkMode),
                  const SizedBox(height: 12),
                  _buildThemeSelector(isDarkMode),
                  const SizedBox(height: 24),

                  // --- INFORMATIONS ---
                  _buildSectionTitle('Informations', isDarkMode),
                  const SizedBox(height: 12),
                  _buildInfoCard(title: 'Version de l\'app', value: 'v1.0.0 (Build 24)', isDarkMode: isDarkMode),
                  const SizedBox(height: 8),
                  _buildInfoCard(title: 'Dernier check-in', value: 'Il y a 2 minutes', isDarkMode: isDarkMode),
                  const SizedBox(height: 8),
                  _buildInfoCard(title: 'Appareil lié', value: 'Samsung Galaxy A12', isDarkMode: isDarkMode),
                  const SizedBox(height: 24),

                  // --- ACTIONS ---
                  _buildSectionTitle('Actions', isDarkMode),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    label: 'Exporter mes données',
                    icon: Icons.download,
                    color: AppTheme.accentBlue,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export en cours...')));
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    label: 'Réinitialiser les paramètres',
                    icon: Icons.refresh,
                    color: AppTheme.activityOrange,
                    onPressed: _showResetDialog,
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    label: 'Déconnexion',
                    icon: Icons.logout,
                    color: AppTheme.activityRed,
                    onPressed: _showLogoutDialog,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === WIDGETS HELPERS ===

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1a1a1a),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? AppTheme.darkBgLight : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.accentBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.accentBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required String content,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? AppTheme.darkBgLight : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.accentBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1a1a1a),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF666666),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDarkMode) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? AppTheme.darkBgLight : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: AppTheme.accentBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Thème',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1a1a1a),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThemeButton('☀️ Clair', 'light', isDarkMode),
                _buildThemeButton('🌙 Sombre', 'dark', isDarkMode),
                _buildThemeButton('🔄 Auto', 'auto', isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(String label, String theme, bool isDarkMode) {
    final isSelected = selectedTheme == theme;
    return GestureDetector(
      onTap: () => setState(() => selectedTheme = theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.accentBlue
                : (isDarkMode ? AppTheme.textSecondary.withValues(alpha: 0.3) : const Color(0xFFcccccc)),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.accentBlue : (isDarkMode ? AppTheme.textSecondary : const Color(0xFF666666)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkBgLight : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? AppTheme.textSecondary.withValues(alpha: 0.1) : const Color(0xFFe0e0e0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1a1a1a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // === DIALOGS ===

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres?'),
        content: const Text('Tous les paramètres seront restaurés à leurs valeurs par défaut.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isOnVacation = false;
                notificationsEnabled = true;
                locationTrackingEnabled = true;
                alertsEnabled = true;
                dataCollectionEnabled = true;
                selectedTheme = 'auto';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres réinitialisés')));
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion?'),
        content: const Text('Vous serez déconnecté de l\'application.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnexion en cours...')));
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

