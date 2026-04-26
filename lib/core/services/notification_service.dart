import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'digital_khata_channel',
      'Digital Khata Notifications',
      channelDescription: 'Notifications for Digital Khata app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> showLowStockAlert({
    required String productName,
    required int currentStock,
    required int minStock,
  }) async {
    await showNotification(
      id: currentStock.hashCode,
      title: 'Low Stock Alert',
      body: '$productName is running low ($currentStock/$minStock)',
    );
  }

  static Future<void> showSaleNotification({
    required String invoiceNumber,
    required double amount,
  }) async {
    await showNotification(
      id: invoiceNumber.hashCode,
      title: 'Sale Completed',
      body: 'Invoice $invoiceNumber - Rs. ${amount.toStringAsFixed(2)}',
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
