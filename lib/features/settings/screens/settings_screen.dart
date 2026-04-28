import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_settings_provider.dart';
import 'tax_settings_screen.dart';
import 'invoice_settings_screen.dart';
import 'preferences_screen.dart';
import 'backup_restore_screen.dart';
import 'import_export_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              context,
              title: 'Business Settings',
              items: [
                _SettingItem(
                  icon: Icons.business,
                  title: 'Business Profile',
                  subtitle: 'Name, address, logo',
                  onTap: () => context.push('/business-profile'),
                ),
                _SettingItem(
                  icon: Icons.receipt_long,
                  title: 'Invoice Settings',
                  subtitle: 'Prefix: ${settings.invoicePrefix}',
                  onTap: () => _navigateToInvoiceSettings(context),
                ),
                _SettingItem(
                  icon: Icons.percent,
                  title: 'Tax Settings',
                  subtitle: 'VAT: ${settings.vatRate}%',
                  onTap: () => _navigateToTaxSettings(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Data Management',
              items: [
                _SettingItem(
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  subtitle: 'Google Drive or Local backup',
                  onTap: () => _navigateToBackupRestore(context),
                ),
                _SettingItem(
                  icon: Icons.import_export,
                  title: 'Import/Export',
                  subtitle: 'Zip, CSV, Excel',
                  onTap: () => _navigateToImportExport(context),
                ),

              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Preferences',
              items: [
                _SettingItem(
                  icon: Icons.settings_outlined,
                  title: 'App Preferences',
                  subtitle: 'Language: ${settings.language == 'en' ? 'English' : 'नेपाली'}, Calendar: ${settings.calendarType.toUpperCase()}',
                  onTap: () => _navigateToPreferences(context),
                ),
                _SettingItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  subtitle: _getThemeLabel(settings.themeMode),
                  onTap: () => _showThemeDialog(context, ref, settings.themeMode),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'About',
              items: [
                _SettingItem(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'View privacy policy',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'View terms',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SettingItem> items,
  }) {
    return Card(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ...items.map((item) => _buildSettingTile(context, item)),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, _SettingItem item) {
    return ListTile(
      leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }

  void _navigateToTaxSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaxSettingsScreen()),
    );
  }

  void _navigateToInvoiceSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen()),
    );
  }

  void _navigateToPreferences(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreferencesScreen()),
    );
  }

  void _navigateToBackupRestore(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
    );
  }

  void _navigateToImportExport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportExportScreen()),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                ref.read(appSettingsNotifierProvider.notifier).updateThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                ref.read(appSettingsNotifierProvider.notifier).updateThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                ref.read(appSettingsNotifierProvider.notifier).updateThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
