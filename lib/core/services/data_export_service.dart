import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import '../database/app_database.dart';

enum ExportMode { fast, full }

class DataExportService {
  final AppDatabase db;
  DataExportService(this.db);

  Future<File> exportToExcel({
    ExportMode mode = ExportMode.full,
    void Function(double progress, String step)? onProgress,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    onProgress?.call(0.05, 'Loading products…');
    final products = await (db.select(db.products)
          ..orderBy([(t) => drift.OrderingTerm.asc(t.id)]))
        .get();
    onProgress?.call(0.15, 'Building Products sheet…');
    _buildProductsSheet(excel, products);

    onProgress?.call(0.25, 'Loading categories…');
    final categories = await _getUniqueCategories(products);
    _buildCategoriesSheet(excel, categories);

    onProgress?.call(0.35, 'Loading customers…');
    final customers = await (db.select(db.customers)
          ..orderBy([(t) => drift.OrderingTerm.asc(t.id)]))
        .get();
    _buildCustomersSheet(excel, customers);

    onProgress?.call(0.50, 'Loading transactions…');
    final transactions = await (db.select(db.transactions)
          ..orderBy([(t) => drift.OrderingTerm.desc(t.transactionDate)]))
        .get();
    _buildTransactionsSheet(excel, transactions);

    onProgress?.call(0.60, 'Loading transaction items…');
    final transactionItems = await db.select(db.transactionItems).get();
    _buildTransactionItemsSheet(excel, transactionItems);

    onProgress?.call(0.70, 'Loading business profile…');
    final settings = await db.select(db.settings).get();
    _buildBusinessProfileSheet(excel, settings);

    onProgress?.call(0.80, 'Loading settings…');
    _buildSettingsSheet(excel, settings);

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final xlsxPath = p.join(dir.path, 'hamropasal_export_$ts.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file');
    final xlsxFile = File(xlsxPath);
    await xlsxFile.writeAsBytes(bytes);

    if (mode == ExportMode.full) {
      onProgress?.call(0.90, 'Copying product images…');
      final imagesDir = Directory(p.join(dir.path, 'hamropasal_images_$ts'));
      await imagesDir.create(recursive: true);
      for (final product in products) {
        if (product.imagePath != null) {
          final src = File(product.imagePath!);
          if (await src.exists()) {
            final dest = File(p.join(imagesDir.path, p.basename(product.imagePath!)));
            await src.copy(dest.path);
          }
        }
      }
    }

    onProgress?.call(1.0, 'Export complete!');
    return xlsxFile;
  }

  Future<List<String>> _getUniqueCategories(List<Product> products) async {
    final categories = <String>{};
    for (final product in products) {
      if (product.category != null && product.category!.isNotEmpty) {
        categories.add(product.category!);
      }
    }
    return categories.toList();
  }

  Future<Map<String, String?>> _getBusinessProfile(List<Setting> settings) async {
    final profile = <String, String?>{};
    for (final s in settings) {
      if (s.key.startsWith('business_')) {
        profile[s.key] = s.value;
      }
    }
    return profile;
  }

  void _buildProductsSheet(Excel excel, List<Product> products) {
    final sheet = excel['Products'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E21B22'),
      fontColorHex: ExcelColor.white,
    );
    final headers = [
      'ID', 'Name', 'Name (Nepali)', 'Barcode', 'SKU',
      'Sale Price', 'Cost Price', 'Stock', 'Min Stock',
      'Unit', 'Category', 'Is Active', 'Expiry Date', 'Image Path',
    ];
    _addHeaderRow(sheet, headers, headerStyle);
    for (final r in products) {
      sheet.appendRow([
        IntCellValue(r.id),
        TextCellValue(r.name),
        TextCellValue(r.nameNepali ?? ''),
        TextCellValue(r.barcode ?? ''),
        TextCellValue(r.sku ?? ''),
        DoubleCellValue(r.price),
        DoubleCellValue(r.costPrice),
        IntCellValue(r.stock),
        IntCellValue(r.minStock),
        TextCellValue(r.unit),
        TextCellValue(r.category ?? ''),
        BoolCellValue(r.isActive),
        TextCellValue(r.expiryDate?.toIso8601String() ?? ''),
        TextCellValue(r.imagePath ?? ''),
      ]);
    }
  }

  void _buildCategoriesSheet(Excel excel, List<String> categories) {
    final sheet = excel['Categories'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FF9800'),
      fontColorHex: ExcelColor.white,
    );
    _addHeaderRow(sheet, ['Category Name', 'Products Count'], headerStyle);
    final counts = <String, int>{};
    for (final c in categories) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    for (final c in categories) {
      sheet.appendRow([
        TextCellValue(c),
        IntCellValue(counts[c] ?? 0),
      ]);
    }
  }

  void _buildCustomersSheet(Excel excel, List<Customer> customers) {
    final sheet = excel['Customers'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.white,
    );
    _addHeaderRow(sheet, [
      'ID', 'Name', 'Phone', 'Email', 'Address', 'PAN', 'Balance', 'Is Active',
    ], headerStyle);
    for (final r in customers) {
      sheet.appendRow([
        IntCellValue(r.id),
        TextCellValue(r.name),
        TextCellValue(r.phone ?? ''),
        TextCellValue(r.email ?? ''),
        TextCellValue(r.address ?? ''),
        TextCellValue(r.panNumber ?? ''),
        DoubleCellValue(r.balance),
        BoolCellValue(r.isActive),
      ]);
    }
  }

  void _buildTransactionsSheet(Excel excel, List<Transaction> transactions) {
    final sheet = excel['Transactions'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
      fontColorHex: ExcelColor.white,
    );
    _addHeaderRow(sheet, [
      'ID', 'Invoice #', 'Type', 'Customer ID', 'Customer Name',
      'Customer Phone', 'Customer Address', 'Customer PAN',
      'Amount', 'VAT', 'Total', 'Payment Method', 'Date', 'Notes',
    ], headerStyle);
    for (final r in transactions) {
      sheet.appendRow([
        IntCellValue(r.id),
        TextCellValue(r.invoiceNumber),
        TextCellValue(r.type),
        r.customerId != null ? IntCellValue(r.customerId!) : null,
        TextCellValue(r.customerName ?? ''),
        TextCellValue(r.customerPhone ?? ''),
        TextCellValue(r.customerAddress ?? ''),
        TextCellValue(r.customerPan ?? ''),
        DoubleCellValue(r.amount),
        DoubleCellValue(r.vatAmount),
        DoubleCellValue(r.totalAmount),
        TextCellValue(r.paymentMethod),
        TextCellValue(r.transactionDate.toIso8601String()),
        TextCellValue(r.notes ?? ''),
      ]);
    }
  }

  void _buildTransactionItemsSheet(Excel excel, List<TransactionItem> items) {
    final sheet = excel['Transaction_Items'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#00897B'),
      fontColorHex: ExcelColor.white,
    );
    _addHeaderRow(sheet, [
      'ID', 'Transaction ID', 'Product ID', 'Quantity', 'Unit Price', 'Total Price', 'Variant',
    ], headerStyle);
    for (final r in items) {
      sheet.appendRow([
        IntCellValue(r.id),
        IntCellValue(r.transactionId),
        IntCellValue(r.productId),
        IntCellValue(r.quantity),
        DoubleCellValue(r.unitPrice),
        DoubleCellValue(r.totalPrice),
        TextCellValue(r.selectedVariant ?? ''),
      ]);
    }
  }

  void _buildBusinessProfileSheet(Excel excel, List<Setting> settings) {
    final sheet = excel['Business_Profile'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.white,
    );
    _addHeaderRow(sheet, ['Field', 'Value'], headerStyle);
    
    final profileData = <String, String>{};
    for (final s in settings) {
      if (s.key.startsWith('business_')) {
        profileData[s.key.replaceFirst('business_', '')] = s.value;
      }
    }
    
    final fields = ['name', 'address', 'phone', 'email', 'pan', 'logo'];
    for (final key in fields) {
      final value = profileData[key] ?? profileData[key == 'name' ? 'businessName' : ''] ?? '';
      if (value.isNotEmpty) {
        sheet.appendRow([
          TextCellValue(key == 'name' ? 'Business Name' : key[0].toUpperCase() + key.substring(1)),
          TextCellValue(value),
        ]);
      }
    }
  }

  void _buildSettingsSheet(Excel excel, List<Setting> settings) {
    final sheet = excel['Settings'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#37474F'),
      fontColorHex: ExcelColor.white,
    );
    _addHeaderRow(sheet, ['Key', 'Value', 'Updated At'], headerStyle);
    for (final s in settings) {
      sheet.appendRow([
        TextCellValue(s.key),
        TextCellValue(s.value),
        TextCellValue(s.updatedAt.toIso8601String()),
      ]);
    }
  }

  void _addHeaderRow(Sheet sheet, List<String> headers, CellStyle style) {
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = style;
    }
  }

  Future<File> exportToCsv(
    String type, {
    void Function(double progress, String step)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();

    onProgress?.call(0.1, 'Loading $type…');

    switch (type) {
      case 'products':
        buffer.writeln(
            'ID,Name,Name (Nepali),Barcode,SKU,Price,Cost Price,Stock,Min Stock,Unit,Category,Is Active,Expiry Date,Image Path');
        final rows = await db.select(db.products).get();
        for (final r in rows) {
          buffer.writeln(
              '${r.id},${_csv(r.name)},${_csv(r.nameNepali)},${_csv(r.barcode)},${_csv(r.sku)},${r.price},${r.costPrice},${r.stock},${r.minStock},${r.unit},${_csv(r.category)},${r.isActive},${r.expiryDate?.toIso8601String() ?? ''},${_csv(r.imagePath)}');
        }
      case 'customers':
        buffer.writeln('ID,Name,Phone,Email,Address,PAN,Balance,Is Active');
        final rows = await db.select(db.customers).get();
        for (final r in rows) {
          buffer.writeln(
              '${r.id},${_csv(r.name)},${_csv(r.phone)},${_csv(r.email)},${_csv(r.address)},${_csv(r.panNumber)},${r.balance},${r.isActive}');
        }
      case 'transactions':
        buffer.writeln(
            'ID,Invoice,Type,Customer,Amount,VAT,Total,Payment Method,Date,Notes');
        final rows = await db.select(db.transactions).get();
        for (final r in rows) {
          buffer.writeln(
              '${r.id},${_csv(r.invoiceNumber)},${r.type},${_csv(r.customerName)},${r.amount},${r.vatAmount},${r.totalAmount},${r.paymentMethod},${r.transactionDate.toIso8601String()},${_csv(r.notes)}');
        }
      default:
        throw ArgumentError('Unknown type: $type');
    }

    final file = File(p.join(dir.path, '${type}_$ts.csv'));
    await file.writeAsString(buffer.toString());
    onProgress?.call(1.0, 'CSV export complete!');
    return file;
  }

  Future<File> exportEverythingAsZip({
    void Function(double progress, String step)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tempDir = Directory(p.join(dir.path, 'hamropasal_export_temp_$ts'));
    await tempDir.create(recursive: true);

    try {
      onProgress?.call(0.1, 'Generating Excel file…');
      final excelFile = await exportToExcel(
        mode: ExportMode.fast,
        onProgress: (p, s) => onProgress?.call(0.1 + (p * 0.3), s),
      );
      await excelFile.copy(p.join(tempDir.path, 'Database_Full.xlsx'));
      await excelFile.delete();

      onProgress?.call(0.4, 'Generating Products CSV…');
      final prodCsv = await exportToCsv('products');
      await prodCsv.copy(p.join(tempDir.path, 'Products.csv'));
      await prodCsv.delete();

      onProgress?.call(0.5, 'Generating Customers CSV…');
      final custCsv = await exportToCsv('customers');
      await custCsv.copy(p.join(tempDir.path, 'Customers.csv'));
      await custCsv.delete();

      onProgress?.call(0.6, 'Generating Transactions CSV…');
      final transCsv = await exportToCsv('transactions');
      await transCsv.copy(p.join(tempDir.path, 'Transactions.csv'));
      await transCsv.delete();

      onProgress?.call(0.7, 'Copying Images…');
      final imagesDir = Directory(p.join(tempDir.path, 'images'));
      await imagesDir.create();

      final products = await db.select(db.products).get();
      for (final product in products) {
        if (product.imagePath != null) {
          final src = File(product.imagePath!);
          if (await src.exists()) {
            final dest = File(p.join(imagesDir.path, p.basename(product.imagePath!)));
            await src.copy(dest.path);
          }
        }
      }

      onProgress?.call(0.9, 'Compressing everything to ZIP…');
      final zipEncoder = ZipFileEncoder();
      final zipPath = p.join(dir.path, 'HamroByapar_Export_$ts.zip');
      zipEncoder.create(zipPath);
      zipEncoder.addDirectory(tempDir);
      zipEncoder.close();

      onProgress?.call(1.0, 'Export complete!');
      return File(zipPath);
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  String _csv(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}