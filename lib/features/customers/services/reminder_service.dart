import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../../../core/utils/currency_formatter.dart';

class ReminderService {
  static Future<bool> sendWhatsAppReminder({
    required CustomerModel customer,
    required double amount,
    String? dueDate,
  }) async {
    if (customer.phone == null || customer.phone!.isEmpty) {
      return false;
    }

    final message = _generateReminderMessage(
      customerName: customer.name,
      amount: amount,
      dueDate: dueDate,
    );

    final phone = customer.phone!.replaceAll(RegExp(r'[^\d+]'), '');
    final whatsappUrl = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        return await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendViberReminder({
    required CustomerModel customer,
    required double amount,
    String? dueDate,
  }) async {
    if (customer.phone == null || customer.phone!.isEmpty) {
      return false;
    }

    final message = _generateReminderMessage(
      customerName: customer.name,
      amount: amount,
      dueDate: dueDate,
    );

    final phone = customer.phone!.replaceAll(RegExp(r'[^\d+]'), '');
    final viberUrl = Uri.parse('viber://chat?number=$phone&text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(viberUrl)) {
        return await launchUrl(viberUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendSMSReminder({
    required CustomerModel customer,
    required double amount,
    String? dueDate,
  }) async {
    if (customer.phone == null || customer.phone!.isEmpty) {
      return false;
    }

    final message = _generateReminderMessage(
      customerName: customer.name,
      amount: amount,
      dueDate: dueDate,
    );

    final phone = customer.phone!.replaceAll(RegExp(r'[^\d+]'), '');
    final smsUrl = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(smsUrl)) {
        return await launchUrl(smsUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static String _generateReminderMessage({
    required String customerName,
    required double amount,
    String? dueDate,
  }) {
    final formattedAmount = CurrencyFormatter.format(amount);
    
    if (dueDate != null && dueDate.isNotEmpty) {
      return '''Dear $customerName,

This is a friendly reminder about your pending payment.

Amount Due: $formattedAmount
Due Date: $dueDate

Please make the payment at your earliest convenience.

Thank you for your business!
- HamroByapar''';
    } else {
      return '''Dear $customerName,

This is a friendly reminder about your pending payment.

Amount Due: $formattedAmount

Please make the payment at your earliest convenience.

Thank you for your business!
- HamroByapar''';
    }
  }
}
