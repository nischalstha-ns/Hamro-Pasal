class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Digital Khata';
  static const String appNameNepali = 'डिजिटल खाता';

  // Nepal Specific
  static const String currency = 'Rs.';
  static const String currencyNepali = 'रु';
  static const double defaultVatRate = 0.13; // 13%

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double minWidth = 360.0;

  // Database
  static const String databaseName = 'digital_khata.db';
  static const int databaseVersion = 1;

  // Date Formats
  static const String dateFormatBS = 'yyyy/MM/dd';
  static const String dateFormatAD = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Fiscal Year (BS)
  static const int fiscalYearStartMonth = 4; // Shrawan
  static const int fiscalYearStartDay = 1;
  static const int fiscalYearEndMonth = 3; // Ashadh
  static const int fiscalYearEndDay = 32;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];

  // Backup
  static const String backupFolderName = 'DigitalKhataBackups';
  static const Duration autoBackupInterval = Duration(days: 7);
}
