import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  // Format: Rs. 1,23,456.00
  static String format(double amount, {bool isNepali = false}) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    final formatted = formatter.format(amount);
    final currency = isNepali ? 'रु' : 'Rs.';
    return '$currency $formatted';
  }

  // Format without decimal: Rs. 1,23,456
  static String formatWhole(int amount, {bool isNepali = false}) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    final formatted = formatter.format(amount);
    final currency = isNepali ? 'रु' : 'Rs.';
    return '$currency $formatted';
  }

  // Parse formatted string to double
  static double parse(String formattedAmount) {
    final cleaned = formattedAmount
        .replaceAll('Rs.', '')
        .replaceAll('रु', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  // Calculate VAT
  static double calculateVat(double amount, double vatRate) {
    return amount * vatRate;
  }

  // Calculate amount with VAT
  static double addVat(double amount, double vatRate) {
    return amount * (1 + vatRate);
  }

  // Calculate amount without VAT
  static double removeVat(double amountWithVat, double vatRate) {
    return amountWithVat / (1 + vatRate);
  }
}
