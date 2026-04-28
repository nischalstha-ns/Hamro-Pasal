import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import 'data_export_service.dart';

const _kManifestVersion = '2';
const _kBackupExtension = 'zip';

class RestoreResult {
  final int products;
  final int customers;
  final int transactions;
  final int settings;
  final List<String> warnings;
  const RestoreResult({
    required this.products,
    required this.customers,
    required this.transactions,
    required this.settings,
    this.warnings = const [],
  });
}

class BackupManifest {
  final String version;
  final String createdAt;
  final int productCount;
  final int customerCount;
  final int transactionCount;
  final int settingCount;
  const BackupManifest({
    required this.version,
    required this.createdAt,
    required this.productCount,
    required this.customerCount,
    required this.transactionCount,
    required this.settingCount,
  });
  factory BackupManifest.fromJson(Map<String, dynamic> j) => BackupManifest(
        version: j['version'] as String? ?? '',
        createdAt: j['createdAt'] as String? ?? '',
        productCount: j['productCount'] as int? ?? 0,
        customerCount: j['customerCount'] as int? ?? 0,
        transactionCount: j['transactionCount'] as int? ?? 0,
        settingCount: j['settingCount'] as int? ?? 0,
      );
  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt,
        'productCount': productCount,
        'customerCount': customerCount,
        'transactionCount': transactionCount,
        'settingCount': settingCount,
      };
}

class BackupService {
  final AppDatabase db;
  BackupService(this.db);

  // ─────────────────────────────────────────────────────
  // CREATE BACKUP
  // ─────────────────────────────────────────────────────

  /// Creates a full .hpbackup zip containing JSON data + product images.
  Future<File> createBackup({
    void Function(double progress, String step)? onProgress,
  }) async {
    onProgress?.call(0.05, 'Reading products…');
    final products = await db.select(db.products).get();
    onProgress?.call(0.15, 'Reading customers…');
    final customers = await db.select(db.customers).get();
    onProgress?.call(0.25, 'Reading transactions…');
    final transactions = await db.select(db.transactions).get();
    onProgress?.call(0.30, 'Reading transaction items…');
    final txItems = await db.select(db.transactionItems).get();
    onProgress?.call(0.35, 'Reading settings…');
    final settings = await db.select(db.settings).get();

    final manifest = BackupManifest(
      version: _kManifestVersion,
      createdAt: DateTime.now().toIso8601String(),
      productCount: products.length,
      customerCount: customers.length,
      transactionCount: transactions.length,
      settingCount: settings.length,
    );

    onProgress?.call(0.40, 'Serialising data…');
    final dataJson = jsonEncode({
      'products': products.map((p) => p.toJson()).toList(),
      'customers': customers.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'transactionItems': txItems.map((i) => i.toJson()).toList(),
      'settings': settings.map((s) => s.toJson()).toList(),
    });

    final archive = Archive();
    _addText(archive, 'manifest.json', jsonEncode(manifest.toJson()));
    _addText(archive, 'data.json', dataJson);

    onProgress?.call(0.55, 'Packaging product images…');
    int imageCount = 0;
    for (final product in products) {
      if (product.imagePath != null) {
        final imgFile = File(product.imagePath!);
        if (await imgFile.exists()) {
          final bytes = await imgFile.readAsBytes();
          archive.addFile(
            ArchiveFile('images/${p.basename(product.imagePath!)}', bytes.length, bytes),
          );
          imageCount++;
        }
      }
    }
    onProgress?.call(0.70, 'Generating Excel snapshot…');
    final exportService = DataExportService(db);
    final excelFile = await exportService.exportToExcel(mode: ExportMode.fast);
    final excelBytes = await excelFile.readAsBytes();
    archive.addFile(ArchiveFile('Database_Full.xlsx', excelBytes.length, excelBytes));
    await excelFile.delete();

    onProgress?.call(0.85, 'Packed $imageCount image(s), compressing…');

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Failed to create backup archive');

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'hamropasal_backup_$ts.$_kBackupExtension'));
    await file.writeAsBytes(zipBytes);

    onProgress?.call(1.0, 'Backup created (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)');
    return file;
  }

  // ─────────────────────────────────────────────────────
  // PREVIEW MANIFEST (before restore)
  // ─────────────────────────────────────────────────────

  Future<BackupManifest> readManifest(File backupFile) async {
    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) throw Exception('Invalid backup file: no manifest');
    final json = jsonDecode(utf8.decode(manifestFile.content as List<int>));
    return BackupManifest.fromJson(json as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────
  // RESTORE BACKUP
  // ─────────────────────────────────────────────────────

  Future<RestoreResult> restoreBackup(
    File backupFile, {
    void Function(double progress, String step)? onProgress,
  }) async {
    onProgress?.call(0.05, 'Reading backup file…');
    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) throw Exception('Invalid backup: no manifest.json');
    final manifest = BackupManifest.fromJson(
        jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>);

    if (manifest.version != _kManifestVersion &&
        manifest.version != '1') {
      throw Exception('Unsupported backup version: ${manifest.version}');
    }

    final dataFile = archive.findFile('data.json');
    if (dataFile == null) throw Exception('Invalid backup: no data.json');
    final data = jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map<String, dynamic>;

    onProgress?.call(0.20, 'Clearing existing data…');
    // Full replace — delete in FK-safe order
    await db.delete(db.transactionItems).go();
    await db.delete(db.transactions).go();
    await db.delete(db.products).go();
    await db.delete(db.customers).go();
    await db.delete(db.settings).go();

    // Restore images first so imagePaths are valid
    onProgress?.call(0.30, 'Restoring images…');
    final appDir = await getApplicationDocumentsDirectory();
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.startsWith('images/')) continue;
      final dest = File(p.join(appDir.path, p.basename(file.name)));
      await dest.writeAsBytes(file.content as List<int>);
    }

    onProgress?.call(0.40, 'Restoring settings…');
    final settingsJson = data['settings'] as List? ?? [];
    for (final s in settingsJson) {
      final map = s as Map<String, dynamic>;
      await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: map['key'] as String, value: map['value'] as String),
      );
    }

    onProgress?.call(0.50, 'Restoring products…');
    final productsJson = data['products'] as List? ?? [];
    for (final p in productsJson) {
      final map = p as Map<String, dynamic>;
      await _restoreProduct(map, appDir.path);
    }

    onProgress?.call(0.65, 'Restoring customers…');
    final customersJson = data['customers'] as List? ?? [];
    for (final c in customersJson) {
      await _restoreCustomer(c as Map<String, dynamic>);
    }

    onProgress?.call(0.80, 'Restoring transactions…');
    final txJson = data['transactions'] as List? ?? [];
    final txItemsJson = data['transactionItems'] as List? ?? [];
    for (final t in txJson) {
      await _restoreTransaction(t as Map<String, dynamic>);
    }
    for (final i in txItemsJson) {
      await _restoreTransactionItem(i as Map<String, dynamic>);
    }

    onProgress?.call(1.0, 'Restore complete!');
    return RestoreResult(
      products: productsJson.length,
      customers: customersJson.length,
      transactions: txJson.length,
      settings: settingsJson.length,
    );
  }

  // ─────────────────────────────────────────────────────
  // RESTORE HELPERS
  // ─────────────────────────────────────────────────────

  Future<void> _restoreProduct(Map<String, dynamic> m, String appDirPath) async {
    // Fix imagePath to point to app documents dir
    String? imagePath = m['image_path'] as String?;
    if (imagePath != null) {
      final filename = p.basename(imagePath);
      imagePath = p.join(appDirPath, filename);
    }
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        nameNepali: drift.Value(m['name_nepali'] as String?),
        description: drift.Value(m['description'] as String?),
        barcode: drift.Value(m['barcode'] as String?),
        sku: drift.Value(m['sku'] as String?),
        costPrice: drift.Value((m['cost_price'] as num?)?.toDouble() ?? 0.0),
        stock: drift.Value(m['stock'] as int? ?? 0),
        minStock: drift.Value(m['min_stock'] as int? ?? 0),
        unit: drift.Value(m['unit'] as String? ?? 'pcs'),
        category: drift.Value(m['category'] as String?),
        imagePath: drift.Value(imagePath),
        isActive: drift.Value(m['is_active'] as bool? ?? true),
        expiryAlertEnabled: drift.Value(m['expiry_alert_enabled'] as bool? ?? false),
        expiryAlertDays: drift.Value(m['expiry_alert_days'] as int? ?? 7),
      ),
      mode: drift.InsertMode.insertOrReplace,
    );
  }

  Future<void> _restoreCustomer(Map<String, dynamic> m) async {
    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        name: m['name'] as String,
        phone: drift.Value(m['phone'] as String?),
        email: drift.Value(m['email'] as String?),
        address: drift.Value(m['address'] as String?),
        panNumber: drift.Value(m['pan_number'] as String?),
        balance: drift.Value((m['balance'] as num?)?.toDouble() ?? 0.0),
        isActive: drift.Value(m['is_active'] as bool? ?? true),
      ),
      mode: drift.InsertMode.insertOrReplace,
    );
  }

  Future<void> _restoreTransaction(Map<String, dynamic> m) async {
    await db.into(db.transactions).insert(
      TransactionsCompanion.insert(
        invoiceNumber: m['invoice_number'] as String,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        totalAmount: (m['total_amount'] as num).toDouble(),
        paymentMethod: m['payment_method'] as String,
        transactionDate: DateTime.parse(m['transaction_date'] as String),
        customerId: drift.Value(m['customer_id'] as int?),
        customerName: drift.Value(m['customer_name'] as String?),
        customerPhone: drift.Value(m['customer_phone'] as String?),
        customerAddress: drift.Value(m['customer_address'] as String?),
        customerPan: drift.Value(m['customer_pan'] as String?),
        vatAmount: drift.Value((m['vat_amount'] as num?)?.toDouble() ?? 0.0),
        notes: drift.Value(m['notes'] as String?),
        attachments: drift.Value(m['attachments'] as String?),
      ),
      mode: drift.InsertMode.insertOrReplace,
    );
  }

  Future<void> _restoreTransactionItem(Map<String, dynamic> m) async {
    await db.into(db.transactionItems).insert(
      TransactionItemsCompanion.insert(
        transactionId: m['transaction_id'] as int,
        productId: m['product_id'] as int,
        quantity: m['quantity'] as int,
        unitPrice: (m['unit_price'] as num).toDouble(),
        totalPrice: (m['total_price'] as num).toDouble(),
      ),
      mode: drift.InsertMode.insertOrIgnore,
    );
  }

  void _addText(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
}
