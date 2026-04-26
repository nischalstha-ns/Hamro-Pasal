import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

class DateFormatter {
  DateFormatter._();

  // Format AD date
  static String formatAD(DateTime date, {String? format}) {
    final formatter = DateFormat(format ?? 'dd/MM/yyyy');
    return formatter.format(date);
  }

  // Format BS date
  static String formatBS(DateTime date, {String? format}) {
    final nepaliDate = date.toNepaliDateTime();
    return NepaliDateFormat(format ?? 'yyyy/MM/dd').format(nepaliDate);
  }

  // Format with time
  static String formatDateTime(DateTime date, {bool isNepali = false}) {
    if (isNepali) {
      final nepaliDate = date.toNepaliDateTime();
      return '${NepaliDateFormat('yyyy/MM/dd').format(nepaliDate)} ${DateFormat('HH:mm').format(date)}';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Get fiscal year (BS)
  static String getFiscalYear(DateTime date) {
    final nepaliDate = date.toNepaliDateTime();
    // Fiscal year starts from Shrawan 1
    if (nepaliDate.month >= 4) {
      // Shrawan to Chaitra
      return '${nepaliDate.year}/${(nepaliDate.year + 1).toString().substring(2)}';
    } else {
      // Baisakh to Ashadh
      return '${nepaliDate.year - 1}/${nepaliDate.year.toString().substring(2)}';
    }
  }

  // Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime date, {bool isNepali = false}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return isNepali ? '$years वर्ष पहिले' : '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return isNepali ? '$months महिना पहिले' : '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return isNepali ? '${difference.inDays} दिन पहिले' : '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return isNepali ? '${difference.inHours} घण्टा पहिले' : '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return isNepali ? '${difference.inMinutes} मिनेट पहिले' : '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return isNepali ? 'अहिले' : 'Just now';
    }
  }

  // Parse BS date string to DateTime
  static DateTime? parseBSDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final nepaliDate = NepaliDateTime(year, month, day);
      return nepaliDate.toDateTime();
    } catch (e) {
      return null;
    }
  }
}
