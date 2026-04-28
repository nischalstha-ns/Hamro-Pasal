import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import '../models/backup_models.dart';

enum BackupResult {
  success,
  partialSuccess,
  failed,
}

class BackupResultInfo {
  final BackupResult result;
  final String filePath;
  final String fileName;
  final int productCount;
  final int categoryCount;
  final int customerCount;
  final int transactionCount;
  final int transactionItemCount;
  final int settingsCount;
  final List<String> errors;

  BackupResultInfo({
    required this.result,
    required this.filePath,
    required this.fileName,
    required this.productCount,
    required this.categoryCount,
    required this.customerCount,
    required this.transactionCount,
    required this.transactionItemCount,
    required this.settingsCount,
    this.errors = const [],
  });
}

class DataBackupService {
  final AppDatabase db;
  DataBackupService(this.db);

  static const String _version = '3.0';
  static const String _appVersion = '1.0.0';

  Future<BackupResultInfo> createFullBackup({
    void Function(double progress, String step)? onProgress,
  }) async {
    final errors = <String>[];
    final fileName = generateBackupFileName();

    try {
      onProgress?.call(0.05, 'Preparing backup...');

      final tempDir = await getTemporaryDirectory();
      final workDir = Directory(p.join(tempDir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}'));
      await workDir.create(recursive: true);

      final dataDir = Directory(p.join(workDir.path, 'data'));
      final imagesDir = Directory(p.join(workDir.path, 'products', 'images'));
      await dataDir.create(recursive: true);
      await imagesDir.create(recursive: true);

      onProgress?.call(0.08, 'Loading products...');
      final products = await db.select(db.products).get();
      final productsJson = await _exportProducts(products, imagesDir);
      await File(p.join(dataDir.path, 'products.json')).writeAsString(productsJson);

      onProgress?.call(0.20, 'Copying product images...');
      await _copyProductImages(products, imagesDir);

      onProgress?.call(0.30, 'Loading categories...');
      final categories = await _getUniqueCategories(products);
      final categoriesJson = _exportCategories(categories);
      await File(p.join(dataDir.path, 'categories.json')).writeAsString(categoriesJson);

      onProgress?.call(0.35, 'Loading customers...');
      final customers = await db.select(db.customers).get();
      final customersJson = _exportCustomers(customers);
      await File(p.join(dataDir.path, 'customers.json')).writeAsString(customersJson);

      onProgress?.call(0.50, 'Loading transactions...');
      final transactions = await db.select(db.transactions).get();
      final transactionsJson = _exportTransactions(transactions);
      await File(p.join(dataDir.path, 'transactions.json')).writeAsString(transactionsJson);

      onProgress?.call(0.60, 'Loading transaction items...');
      final transactionItems = await db.select(db.transactionItems).get();
      final transactionItemsJson = _exportTransactionItems(transactionItems);
      await File(p.join(dataDir.path, 'transaction_items.json')).writeAsString(transactionItemsJson);

      onProgress?.call(0.70, 'Loading settings & business profile...');
      final settings = await db.select(db.settings).get();
      final settingsJson = _exportSettings(settings);
      await File(p.join(dataDir.path, 'settings.json')).writeAsString(settingsJson);

      onProgress?.call(0.80, 'Creating metadata...');
      final metadata = BackupMetadata(
        id: generateUuid(),
        createdAt: DateTime.now(),
        productCount: products.length,
        categoryCount: categories.length,
        customerCount: customers.length,
        transactionCount: transactions.length,
        transactionItemCount: transactionItems.length,
        settingsCount: settings.length,
        version: _version,
        appVersion: _appVersion,
        settings: {},
      );
      await File(p.join(dataDir.path, 'metadata.json')).writeAsString(
        jsonEncode(metadata.toJson()),
      );

      onProgress?.call(0.85, 'Compressing to ZIP...');
      final zipPath = await _createZipFile(workDir, fileName);

      onProgress?.call(0.95, 'Cleaning up...');
      await workDir.delete(recursive: true);

      onProgress?.call(1.0, 'Backup complete!');

      return BackupResultInfo(
        result: BackupResult.success,
        filePath: zipPath,
        fileName: fileName,
        productCount: products.length,
        categoryCount: categories.length,
        customerCount: customers.length,
        transactionCount: transactions.length,
        transactionItemCount: transactionItems.length,
        settingsCount: settings.length,
        errors: errors,
      );
    } catch (e) {
      return BackupResultInfo(
        result: BackupResult.failed,
        filePath: '',
        fileName: fileName,
        productCount: 0,
        categoryCount: 0,
        customerCount: 0,
        transactionCount: 0,
        transactionItemCount: 0,
        settingsCount: 0,
        errors: [e.toString()],
      );
    }
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

  Future<void> _copyProductImages(List<Product> products, Directory imagesDir) async {
    for (final product in products) {
      if (product.imagePath != null && product.imagePath!.isNotEmpty) {
        final imageFile = File(product.imagePath!);
        if (await imageFile.exists()) {
          final destPath = p.join(imagesDir.path, p.basename(product.imagePath!));
          await imageFile.copy(destPath);
        }
      }
    }
  }

  Future<String> _exportProducts(
    List<Product> products,
    Directory imagesDir,
  ) async {
    final backupProducts = <Map<String, dynamic>>[];

    for (final product in products) {
      String? imageFilename;

      if (product.imagePath != null && product.imagePath!.isNotEmpty) {
        final imageFile = File(product.imagePath!);
        if (await imageFile.exists()) {
          imageFilename = p.basename(product.imagePath!);
        }
      }

      final uuid = _generateProductUuid(product);
      backupProducts.add(BackupProduct(
        uuid: uuid,
        name: product.name,
        nameNepali: product.nameNepali,
        barcode: product.barcode,
        sku: product.sku,
        price: product.price,
        costPrice: product.costPrice,
        stock: product.stock,
        minStock: product.minStock,
        unit: product.unit,
        category: product.category,
        description: product.description,
        imageFilename: imageFilename,
        hasVariants: product.hasVariants,
        variantOptions: product.variantOptions,
        expiryDate: product.expiryDate,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      ).toJson());
    }

    return jsonEncode({
      'products': backupProducts,
    });
  }

  String _exportCategories(List<String> categories) {
    return jsonEncode({
      'categories': categories,
    });
  }

  String _exportCustomers(List<Customer> customers) {
    return jsonEncode({
      'customers': customers.map((c) => BackupCustomer(
        uuid: _generateCustomerUuid(c),
        name: c.name,
        phone: c.phone,
        email: c.email,
        address: c.address,
        panNumber: c.panNumber,
        balance: c.balance,
        isActive: c.isActive,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      ).toJson()).toList(),
    });
  }

  String _exportTransactions(List<Transaction> transactions) {
    return jsonEncode({
      'transactions': transactions.map((t) => BackupTransaction(
        uuid: _generateTransactionUuid(t),
        invoiceNumber: t.invoiceNumber,
        type: t.type,
        customerId: t.customerId,
        customerName: t.customerName,
        customerPhone: t.customerPhone,
        customerAddress: t.customerAddress,
        customerPan: t.customerPan,
        amount: t.amount,
        vatAmount: t.vatAmount,
        totalAmount: t.totalAmount,
        paymentMethod: t.paymentMethod,
        notes: t.notes,
        attachments: t.attachments,
        transactionDate: t.transactionDate,
        createdAt: t.createdAt,
      ).toJson()).toList(),
    });
  }

  String _exportTransactionItems(List<TransactionItem> items) {
    return jsonEncode({
      'transactionItems': items.map((i) => {
        'id': i.id,
        'transactionId': i.transactionId,
        'productId': i.productId,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'totalPrice': i.totalPrice,
        'selectedVariant': i.selectedVariant,
        'createdAt': i.createdAt.toIso8601String(),
      }).toList(),
    });
  }

  String _exportSettings(List<Setting> settings) {
    final settingsMap = <String, String>{};
    for (final s in settings) {
      settingsMap[s.key] = s.value;
    }
    return jsonEncode(settingsMap);
  }

  Future<String> _createZipFile(Directory sourceDir, String fileName) async {
    final archive = Archive();

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir.path);
        final fileBytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(
          relativePath.replaceAll('\\', '/'),
          fileBytes.length,
          fileBytes,
        ));
      }
    }

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData == null) {
      throw Exception('Failed to create ZIP archive');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    await backupDir.create(recursive: true);
    final zipPath = p.join(backupDir.path, fileName);
    await File(zipPath).writeAsBytes(zipData);

    return zipPath;
  }

  String _generateProductUuid(Product product) {
    final hash = '${product.id}_${product.name}_${product.barcode ?? product.sku ?? ''}'.hashCode.abs();
    return 'PRD_$hash';
  }

  String _generateCustomerUuid(Customer customer) {
    final hash = '${customer.id}_${customer.name}_${customer.phone ?? ''}'.hashCode.abs();
    return 'CUS_$hash';
  }

  String _generateTransactionUuid(Transaction transaction) {
    final hash = '${transaction.id}_${transaction.invoiceNumber}'.hashCode.abs();
    return 'TXN_$hash';
  }
}