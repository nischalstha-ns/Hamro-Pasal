import 'dart:convert';

class BackupMetadata {
  final String id;
  final DateTime createdAt;
  final int productCount;
  final int categoryCount;
  final int customerCount;
  final int transactionCount;
  final int transactionItemCount;
  final int settingsCount;
  final String version;
  final String appVersion;
  final Map<String, dynamic> settings;

  BackupMetadata({
    required this.id,
    required this.createdAt,
    required this.productCount,
    required this.categoryCount,
    required this.customerCount,
    required this.transactionCount,
    required this.transactionItemCount,
    required this.settingsCount,
    required this.version,
    required this.appVersion,
    required this.settings,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      productCount: json['productCount'] as int,
      categoryCount: json['categoryCount'] as int,
      customerCount: json['customerCount'] as int,
      transactionCount: json['transactionCount'] as int,
      transactionItemCount: json['transactionItemCount'] as int,
      settingsCount: json['settingsCount'] as int,
      version: json['version'] as String,
      appVersion: json['appVersion'] as String,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'productCount': productCount,
      'categoryCount': categoryCount,
      'customerCount': customerCount,
      'transactionCount': transactionCount,
      'transactionItemCount': transactionItemCount,
      'settingsCount': settingsCount,
      'version': version,
      'appVersion': appVersion,
      'settings': settings,
    };
  }
}

class BackupProduct {
  final String uuid;
  final String name;
  final String? nameNepali;
  final String? barcode;
  final String? sku;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String unit;
  final String? category;
  final String? description;
  final String? imageFilename;
  final bool hasVariants;
  final String? variantOptions;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BackupProduct({
    required this.uuid,
    required this.name,
    this.nameNepali,
    this.barcode,
    this.sku,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    required this.unit,
    this.category,
    this.description,
    this.imageFilename,
    required this.hasVariants,
    this.variantOptions,
    this.expiryDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupProduct.fromJson(Map<String, dynamic> json) {
    return BackupProduct(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      nameNepali: json['nameNepali'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      costPrice: (json['costPrice'] as num).toDouble(),
      stock: json['stock'] as int,
      minStock: json['minStock'] as int,
      unit: json['unit'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      imageFilename: json['imageFilename'] as String?,
      hasVariants: json['hasVariants'] as bool? ?? false,
      variantOptions: json['variantOptions'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'nameNepali': nameNepali,
      'barcode': barcode,
      'sku': sku,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'minStock': minStock,
      'unit': unit,
      'category': category,
      'description': description,
      'imageFilename': imageFilename,
      'hasVariants': hasVariants,
      'variantOptions': variantOptions,
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BackupCustomer {
  final String uuid;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? panNumber;
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BackupCustomer({
    required this.uuid,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.panNumber,
    required this.balance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupCustomer.fromJson(Map<String, dynamic> json) {
    return BackupCustomer(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      panNumber: json['panNumber'] as String?,
      balance: (json['balance'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'panNumber': panNumber,
      'balance': balance,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BackupTransaction {
  final String uuid;
  final String invoiceNumber;
  final String type;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerPan;
  final double amount;
  final double vatAmount;
  final double totalAmount;
  final String paymentMethod;
  final String? notes;
  final String? attachments;
  final DateTime transactionDate;
  final DateTime createdAt;

  BackupTransaction({
    required this.uuid,
    required this.invoiceNumber,
    required this.type,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerPan,
    required this.amount,
    required this.vatAmount,
    required this.totalAmount,
    required this.paymentMethod,
    this.notes,
    this.attachments,
    required this.transactionDate,
    required this.createdAt,
  });

  factory BackupTransaction.fromJson(Map<String, dynamic> json) {
    return BackupTransaction(
      uuid: json['uuid'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      type: json['type'] as String,
      customerId: json['customerId'] as int?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerAddress: json['customerAddress'] as String?,
      customerPan: json['customerPan'] as String?,
      amount: (json['amount'] as num).toDouble(),
      vatAmount: (json['vatAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      notes: json['notes'] as String?,
      attachments: json['attachments'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'invoiceNumber': invoiceNumber,
      'type': type,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerPan': customerPan,
      'amount': amount,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'attachments': attachments,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum DuplicateHandling {
  skip,
  merge,
  replace,
}

class ImportOptions {
  final DuplicateHandling productHandling;
  final DuplicateHandling customerHandling;

  const ImportOptions({
    this.productHandling = DuplicateHandling.skip,
    this.customerHandling = DuplicateHandling.skip,
  });
}

class ImportHistoryRecord {
  final String id;
  final String fileName;
  final DateTime importedAt;
  final String type;
  final int productsImported;
  final int productsSkipped;
  final int customersImported;
  final int customersSkipped;
  final bool success;
  final String? errorMessage;

  ImportHistoryRecord({
    required this.id,
    required this.fileName,
    required this.importedAt,
    required this.type,
    required this.productsImported,
    required this.productsSkipped,
    required this.customersImported,
    required this.customersSkipped,
    required this.success,
    this.errorMessage,
  });

  factory ImportHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ImportHistoryRecord(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
      type: json['type'] as String,
      productsImported: json['productsImported'] as int,
      productsSkipped: json['productsSkipped'] as int,
      customersImported: json['customersImported'] as int,
      customersSkipped: json['customersSkipped'] as int,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'importedAt': importedAt.toIso8601String(),
      'type': type,
      'productsImported': productsImported,
      'productsSkipped': productsSkipped,
      'customersImported': customersImported,
      'customersSkipped': customersSkipped,
      'success': success,
      'errorMessage': errorMessage,
    };
  }
}

class ExportHistoryRecord {
  final String id;
  final String fileName;
  final DateTime exportedAt;
  final int productsExported;
  final int customersExported;
  final int transactionsExported;
  final bool success;
  final String? errorMessage;

  ExportHistoryRecord({
    required this.id,
    required this.fileName,
    required this.exportedAt,
    required this.productsExported,
    required this.customersExported,
    required this.transactionsExported,
    required this.success,
    this.errorMessage,
  });

  factory ExportHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ExportHistoryRecord(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      productsExported: json['productsExported'] as int,
      customersExported: json['customersExported'] as int,
      transactionsExported: json['transactionsExported'] as int,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'exportedAt': exportedAt.toIso8601String(),
      'productsExported': productsExported,
      'customersExported': customersExported,
      'transactionsExported': transactionsExported,
      'success': success,
      'errorMessage': errorMessage,
    };
  }
}

String generateUuid() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = DateTime.now().microsecond;
  return 'UUID_${timestamp}_$random';
}

String generateBackupFileName() {
  final now = DateTime.now();
  final dateStr =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final timeStr =
      '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  final uuid = generateUuid();
  return 'POS_BACKUP_${dateStr}_${timeStr}_$uuid.zip';
}

String generateImportId() {
  final now = DateTime.now();
  return 'IMP_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}';
}

String generateExportId() {
  final now = DateTime.now();
  return 'EXP_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}';
}