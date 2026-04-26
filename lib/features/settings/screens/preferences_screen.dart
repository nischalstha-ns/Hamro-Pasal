import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_settings_provider.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Preferences'),
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Language & Region',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(settings.language == 'en' ? 'English' : 'नेपाली'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Calendar Type'),
                subtitle: Text(
                  settings.calendarType == 'bs'
                      ? 'Bikram Sambat (BS)'
                      : 'Anno Domini (AD)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCalendarDialog(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.currency_rupee),
                title: const Text('Currency'),
                subtitle: Text(settings.currency),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCurrencyDialog(context, ref, settings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive app notifications'),
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .updateNotifications(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.inventory_outlined),
                title: const Text('Low Stock Alerts'),
                subtitle: const Text('Alert when stock is low'),
                value: settings.lowStockAlerts,
                onChanged: (value) {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .updateLowStockAlerts(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Display',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Date Format'),
                subtitle: Text(settings.dateFormat),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDateFormatDialog(context, ref, settings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                ref
                    .read(appSettingsNotifierProvider.notifier)
                    .updateLanguage('en');
                Navigator.pop(dialogContext);
              },
              child: Row(
                children: [
                  RadioListTile<String>(
                    value: 'en',
                    title: const Text('English'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                ref
                    .read(appSettingsNotifierProvider.notifier)
                    .updateLanguage('ne');
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nepali language support coming soon'),
                  ),
                );
              },
              child: Row(
                children: [
                  RadioListTile<String>(
                    value: 'ne',
                    title: const Text('नेपाली (Nepali)'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Calendar Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                ref
                    .read(appSettingsNotifierProvider.notifier)
                    .updateCalendarType('bs');
                Navigator.pop(dialogContext);
              },
              child: Row(
                children: [
                  RadioListTile<String>(
                    value: 'bs',
                    title: const Text('Bikram Sambat (BS)'),
                    subtitle: const Text('Nepali calendar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                ref
                    .read(appSettingsNotifierProvider.notifier)
                    .updateCalendarType('ad');
                Navigator.pop(dialogContext);
              },
              child: Row(
                children: [
                  RadioListTile<String>(
                    value: 'ad',
                    title: const Text('Anno Domini (AD)'),
                    subtitle: const Text('Gregorian calendar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    void update(String v) {
      ref.read(appSettingsNotifierProvider.notifier).updateCurrency(v);
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                update('NPR');
                Navigator.pop(dialogContext);
              },
              child: RadioListTile<String>(
                value: 'NPR',
                title: const Text('NPR - Nepali Rupee'),
                subtitle: const Text('रु', style: TextStyle(fontSize: 12, color: Colors.grey)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            InkWell(
              onTap: () {
                update('INR');
                Navigator.pop(dialogContext);
              },
              child: RadioListTile<String>(
                value: 'INR',
                title: const Text('INR - Indian Rupee'),
                subtitle: const Text('₹', style: TextStyle(fontSize: 12, color: Colors.grey)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            InkWell(
              onTap: () {
                update('USD');
                Navigator.pop(dialogContext);
              },
              child: RadioListTile<String>(
                value: 'USD',
                title: const Text('USD - US Dollar'),
                subtitle: const Text(r'$', style: TextStyle(fontSize: 12, color: Colors.grey)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateFormatDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final now = DateTime.now();
    void update(String v) {
      ref.read(appSettingsNotifierProvider.notifier).updateDateFormat(v);
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                update('yyyy-MM-dd');
                Navigator.pop(dialogContext);
              },
              child: RadioListTile<String>(
                value: 'yyyy-MM-dd',
                title: const Text('yyyy-MM-dd'),
                subtitle: Text(
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            InkWell(
              onTap: () {
                update('dd/MM/yyyy');
                Navigator.pop(dialogContext);
              },
              child: RadioListTile<String>(
                value: 'dd/MM/yyyy',
                title: const Text('dd/MM/yyyy'),
                subtitle: Text(
                  '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            InkWell(
              onTap: () {
                update('MM/dd/yyyy');
                Navigator.pop(dialogContext);
              },
              child: RadioListTile<String>(
                value: 'MM/dd/yyyy',
                title: const Text('MM/dd/yyyy'),
                subtitle: Text(
                  '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
