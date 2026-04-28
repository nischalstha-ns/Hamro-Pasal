import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import '../models/backup_models.dart';

enum RestoreResult {
  success,
  partialSuccess,
  failed,
}

class RestoreResultInfo {
  final RestoreResult result;
  final int productsImported;
  final int productsSkipped;
  final int productsReplaced;
  final int customersImported;
  final int customersSkipped;
  final int customersReplaced;
  final int settingsImported;
  final List<String> errors;
  final List<String> warnings;

  RestoreResultInfo({
    required this.result,
    this.productsImported = 0,
    this.productsSkipped = 0,
    this.productsReplaced = 0,
    this.customersImported = 0,
    this.customersSkipped = 0,
    this.customersReplaced = 0,
    this.settingsImported = 0,
    this.errors = const [],
    this.warnings = const [],
  });
}

class DataRestoreService {
  final AppDatabase db;
  DataRestoreService(this.db);

  Future<RestoreResultInfo> restoreFromZip(
    String zipPath, {
    ImportOptions options = const ImportOptions(),
    void Function(double progress, String step)? onProgress,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    int productsImported = 0;
    int productsSkipped = 0;
    int productsReplaced = 0;
    int customersImported = 0;
    int customersSkipped = 0;
    int customersReplaced = 0;
    int settingsImported = 0;

    try {
      onProgress?.call(0.05, 'Reading ZIP file...');
      final zipFile = File(zipPath);
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      onProgress?.call(0.10, 'Extracting files...');
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(p.join(tempDir.path, 'restore_${DateTime.now().millisecondsSinceEpoch}'));
      await extractDir.create(recursive: true);

      for (final file in archive) {
        if (file.isFile) {
          final filePath = p.join(extractDir.path, file.name);
          await File(filePath).parent.create(recursive: true);
          await File(filePath).writeAsBytes(file.content);
        }
      }

      onProgress?.call(0.25, 'Validating backup structure...');
      final validation = await _validateBackup(extractDir);
      if (!validation.isValid) {
        await extractDir.delete(recursive: true);
        return RestoreResultInfo(
          result: RestoreResult.failed,
          errors: validation.errors,
        );
      }

      final metadata = await _loadMetadata(extractDir);

      onProgress?.call(0.30, 'Processing products...');
      final productsResult = await _restoreProducts(
        extractDir,
        options,
        (p, s) => onProgress?.call(0.30 + (p * 0.35), s),
      );
      productsImported = productsResult.imported;
      productsSkipped = productsResult.skipped;
      productsReplaced = productsResult.replaced;
      errors.addAll(productsResult.errors);
      warnings.addAll(productsResult.warnings);

      onProgress?.call(0.70, 'Processing customers...');
      final customersResult = await _restoreCustomers(
        extractDir,
        options,
        (p, s) => onProgress?.call(0.70 + (p * 0.15), s),
      );
      customersImported = customersResult.imported;
      customersSkipped = customersResult.skipped;
      customersReplaced = customersResult.replaced;
      errors.addAll(customersResult.errors);
      warnings.addAll(customersResult.warnings);

      onProgress?.call(0.90, 'Processing settings & business profile...');
      final settingsResult = await _restoreSettings(extractDir);
      settingsImported = settingsResult;
      errors.addAll(settingsResult.errors);
      warnings.addAll(settingsResult.warnings);

      onProgress?.call(0.95, 'Cleaning up...');
      await extractDir.delete(recursive: true);

      final hasErrors = errors.isNotEmpty;
      onProgress?.call(1.0, hasErrors ? 'Restore complete with errors' : 'Restore complete!');

      return RestoreResultInfo(
        result: hasErrors ? RestoreResult.partialSuccess : RestoreResult.success,
        productsImported: productsImported,
        productsSkipped: productsSkipped,
        productsReplaced: productsReplaced,
        customersImported: customersImported,
        customersSkipped: customersSkipped,
        customersReplaced: customersReplaced,
        settingsImported: settingsImported,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return RestoreResultInfo(
        result: RestoreResult.failed,
        errors: [e.toString()],
      );
    }
  }

  Future<_RestoreItemsResult> _restoreSettings(Directory extractDir) async {
    final errors = <String>[];
    final warnings = <String>[];
    int imported = 0;

    try {
      final settingsFile = File(p.join(extractDir.path, 'data', 'settings.json'));
      if (!await settingsFile.exists()) {
        return _RestoreItemsResult(imported: 0, skipped: 0, replaced: 0);
      }

      final content = await settingsFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      for (final entry in data.entries) {
        try {
          await db.setSetting(entry.key, entry.value.toString());
          imported++;
        } catch (e) {
          errors.add('Setting ${entry.key}: $e');
        }
      }
    } catch (e) {
      errors.add('Settings import error: $e');
    }

    return _RestoreItemsResult(
      imported: imported,
      skipped: 0,
      replaced: 0,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<_ValidationResult> _validateBackup(Directory extractDir) async {
    final errors = <String>[];

    final dataDir = Directory(p.join(extractDir.path, 'data'));
    if (!await dataDir.exists()) {
      errors.add('Missing /data folder in backup');
      return _ValidationResult(isValid: false, errors: errors);
    }

    final productsFile = File(p.join(dataDir.path, 'products.json'));
    final customersFile = File(p.join(dataDir.path, 'customers.json'));
    final metadataFile = File(p.join(dataDir.path, 'metadata.json'));

    if (!await productsFile.exists() && !await customersFile.exists()) {
      errors.add('No valid data files found (products.json or customers.json)');
    }

    if (errors.isNotEmpty) return _ValidationResult(isValid: false, errors: errors);
    return _ValidationResult(isValid: true, errors: []);
  }

  Future<BackupMetadata?> _loadMetadata(Directory extractDir) async {
    try {
      final metadataFile = File(p.join(extractDir.path, 'data', 'metadata.json'));
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        return BackupMetadata.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  Future<_RestoreItemsResult> _restoreProducts(
    Directory extractDir,
    ImportOptions options,
    void Function(double progress, String step)? onProgress,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    int imported = 0;
    int skipped = 0;
    int replaced = 0;

    try {
      final productsFile = File(p.join(extractDir.path, 'data', 'products.json'));
      if (!await productsFile.exists()) {
        return _RestoreItemsResult(imported: 0, skipped: 0, replaced: 0);
      }

      final content = await productsFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final productsJson = data['products'] as List<dynamic>;

      final existingProducts = await db.select(db.products).get();
      final existingBarcodes = <String?>{};
      final existingSkus = <String?>{};
      final existingNames = <String>{};
      for (final p in existingProducts) {
        existingBarcodes.add(p.barcode);
        existingSkus.add(p.sku);
        existingNames.add('${p.name.toLowerCase()}_${p.price}');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(extractDir.path, 'products', 'images'));

      for (int i = 0; i < productsJson.length; i++) {
        onProgress?.call(i / productsJson.length, 'Processing product ${i + 1}/${productsJson.length}');
        try {
          final productJson = productsJson[i] as Map<String, dynamic>;
          final product = BackupProduct.fromJson(productJson);

          final isDuplicate = await _checkDuplicate(
            existingBarcodes,
            existingSkus,
            existingNames,
            product,
          );

          if (isDuplicate) {
            switch (options.productHandling) {
              case DuplicateHandling.skip:
                skipped++;
                warnings.add('Skipped duplicate: ${product.name}');
                continue;
              case DuplicateHandling.replace:
                await _replaceProduct(product, existingProducts);
                replaced++;
                imported++;
                continue;
              case DuplicateHandling.merge:
                await _mergeProductStock(product, existingProducts);
                imported++;
                continue;
            }
          }

          String? finalImagePath;
          if (product.imageFilename != null) {
            final srcImagePath = p.join(imagesDir.path, product.imageFilename!);
            final srcImage = File(srcImagePath);
            if (await srcImage.exists()) {
              final newImageName = 'product_${DateTime.now().millisecondsSinceEpoch}_${product.imageFilename}';
              final destPath = p.join(appDir.path, newImageName);
              await srcImage.copy(destPath);
              finalImagePath = destPath;
            }
          }

          await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: product.name,
              price: product.price,
              costPrice: drift.Value(product.costPrice),
              stock: drift.Value(product.stock),
              minStock: drift.Value(product.minStock),
              unit: drift.Value(product.unit),
              category: drift.Value(product.category),
              description: drift.Value(product.description),
              barcode: drift.Value(product.barcode),
              sku: drift.Value(product.sku),
              nameNepali: drift.Value(product.nameNepali),
              imagePath: drift.Value(finalImagePath),
              hasVariants: drift.Value(product.hasVariants),
              variantOptions: drift.Value(product.variantOptions),
              expiryDate: drift.Value(product.expiryDate),
              isActive: drift.Value(product.isActive),
            ),
          );
          imported++;
        } catch (e) {
          errors.add('Product ${i + 1}: $e');
        }
      }
    } catch (e) {
      errors.add('Products import error: $e');
    }

    return _RestoreItemsResult(
      imported: imported,
      skipped: skipped,
      replaced: replaced,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<bool> _checkDuplicate(
    Set<String?> existingBarcodes,
    Set<String?> existingSkus,
    Set<String> existingNames,
    BackupProduct product,
  ) async {
    if (product.barcode != null && existingBarcodes.contains(product.barcode)) {
      return true;
    }
    if (product.sku != null && existingSkus.contains(product.sku)) {
      return true;
    }
    final nameKey = '${product.name.toLowerCase()}_${product.price}';
    return existingNames.contains(nameKey);
  }

  Future<void> _replaceProduct(BackupProduct product, List<Product> existingProducts) async {
    final existing = existingProducts.firstWhere(
      (p) => p.barcode == product.barcode || p.sku == product.sku,
      orElse: () => existingProducts.first,
    );

    await db.update(db.products).replace(existing.copyWith(
      name: product.name,
      price: product.price,
      costPrice: product.costPrice,
      stock: product.stock,
      minStock: product.minStock,
      unit: product.unit,
      category: drift.Value(product.category),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> _mergeProductStock(BackupProduct product, List<Product> existingProducts) async {
    final existing = existingProducts.firstWhere(
      (p) => p.barcode == product.barcode || p.sku == product.sku,
      orElse: () => existingProducts.first,
    );

    await db.update(db.products).replace(existing.copyWith(
      stock: existing.stock + product.stock,
      updatedAt: DateTime.now(),
    ));
  }

  Future<_RestoreItemsResult> _restoreCustomers(
    Directory extractDir,
    ImportOptions options,
    void Function(double progress, String step)? onProgress,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    int imported = 0;
    int skipped = 0;
    int replaced = 0;

    try {
      final customersFile = File(p.join(extractDir.path, 'data', 'customers.json'));
      if (!await customersFile.exists()) {
        return _RestoreItemsResult(imported: 0, skipped: 0, replaced: 0);
      }

      final content = await customersFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final customersJson = data['customers'] as List<dynamic>;

      final existingCustomers = await db.select(db.customers).get();
      final existingPhones = <String?>{};
      final existingEmails = <String?>{};
      final existingNames = <String>{};
      for (final c in existingCustomers) {
        existingPhones.add(c.phone);
        existingEmails.add(c.email);
        existingNames.add(c.name.toLowerCase());
      }

      for (int i = 0; i < customersJson.length; i++) {
        onProgress?.call(i / customersJson.length, 'Processing customer ${i + 1}/${customersJson.length}');
        try {
          final customerJson = customersJson[i] as Map<String, dynamic>;
          final customer = BackupCustomer.fromJson(customerJson);

          bool isDuplicate = false;
          if (customer.phone != null && existingPhones.contains(customer.phone)) {
            isDuplicate = true;
          }
          if (customer.email != null && existingEmails.contains(customer.email)) {
            isDuplicate = true;
          }
          if (existingNames.contains(customer.name.toLowerCase())) {
            isDuplicate = true;
          }

          if (isDuplicate) {
            switch (options.customerHandling) {
              case DuplicateHandling.skip:
                skipped++;
                warnings.add('Skipped duplicate: ${customer.name}');
                continue;
              case DuplicateHandling.replace:
              case DuplicateHandling.merge:
                replaced++;
                imported++;
                continue;
            }
          }

          await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: customer.name,
              phone: drift.Value(customer.phone),
              email: drift.Value(customer.email),
              address: drift.Value(customer.address),
              panNumber: drift.Value(customer.panNumber),
              balance: drift.Value(customer.balance),
              isActive: drift.Value(customer.isActive),
            ),
          );
          imported++;
        } catch (e) {
          errors.add('Customer ${i + 1}: $e');
        }
      }
    } catch (e) {
      errors.add('Customers import error: $e');
    }

    return _RestoreItemsResult(
      imported: imported,
      skipped: skipped,
      replaced: replaced,
      errors: errors,
      warnings: warnings,
    );
  }
}

class _ValidationResult {
  final bool isValid;
  final List<String> errors;

  _ValidationResult({required this.isValid, required this.errors});
}

class _RestoreItemsResult {
  final int imported;
  final int skipped;
  final int replaced;
  final List<String> errors;
  final List<String> warnings;

  _RestoreItemsResult({
    required this.imported,
    required this.skipped,
    required this.replaced,
    this.errors = const [],
    this.warnings = const [],
  });
}