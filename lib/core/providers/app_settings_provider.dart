import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/products/providers/products_provider.dart';

part 'app_settings_provider.g.dart';

class AppSettings {
  final double vatRate;
  final String language;
  final String calendarType;
  final bool notificationsEnabled;
  final bool lowStockAlerts;
  final String invoicePrefix;
  final String currency;
  final String dateFormat;

  AppSettings({
    required this.vatRate,
    required this.language,
    required this.calendarType,
    required this.notificationsEnabled,
    required this.lowStockAlerts,
    required this.invoicePrefix,
    required this.currency,
    required this.dateFormat,
  });

  AppSettings copyWith({
    double? vatRate,
    String? language,
    String? calendarType,
    bool? notificationsEnabled,
    bool? lowStockAlerts,
    String? invoicePrefix,
    String? currency,
    String? dateFormat,
  }) {
    return AppSettings(
      vatRate: vatRate ?? this.vatRate,
      language: language ?? this.language,
      calendarType: calendarType ?? this.calendarType,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    final db = ref.watch(appDatabaseProvider);
    
    final vatRate = double.tryParse(await db.getSetting('vat_rate') ?? '13') ?? 13.0;
    final language = await db.getSetting('language') ?? 'en';
    final calendarType = await db.getSetting('calendar_type') ?? 'bs';
    final notificationsEnabled = (await db.getSetting('notifications_enabled') ?? 'true') == 'true';
    final lowStockAlerts = (await db.getSetting('low_stock_alerts') ?? 'true') == 'true';
    final invoicePrefix = await db.getSetting('invoice_prefix') ?? 'INV';
    final currency = await db.getSetting('currency') ?? 'NPR';
    final dateFormat = await db.getSetting('date_format') ?? 'yyyy-MM-dd';

    return AppSettings(
      vatRate: vatRate,
      language: language,
      calendarType: calendarType,
      notificationsEnabled: notificationsEnabled,
      lowStockAlerts: lowStockAlerts,
      invoicePrefix: invoicePrefix,
      currency: currency,
      dateFormat: dateFormat,
    );
  }

  Future<void> updateVatRate(double rate) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('vat_rate', rate.toString());
    ref.invalidateSelf();
  }

  Future<void> updateLanguage(String language) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('language', language);
    ref.invalidateSelf();
  }

  Future<void> updateCalendarType(String type) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('calendar_type', type);
    ref.invalidateSelf();
  }

  Future<void> updateNotifications(bool enabled) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('notifications_enabled', enabled.toString());
    ref.invalidateSelf();
  }

  Future<void> updateLowStockAlerts(bool enabled) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('low_stock_alerts', enabled.toString());
    ref.invalidateSelf();
  }

  Future<void> updateInvoicePrefix(String prefix) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('invoice_prefix', prefix);
    ref.invalidateSelf();
  }

  Future<void> updateCurrency(String currency) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('currency', currency);
    ref.invalidateSelf();
  }

  Future<void> updateDateFormat(String format) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting('date_format', format);
    ref.invalidateSelf();
  }
}
