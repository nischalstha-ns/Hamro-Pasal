import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../models/product_model.dart';

class ProductsRepository {
  ProductsRepository(this._database);

  final AppDatabase _database;

  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    final products = await _database.getAllProducts();
    return products.map(_toModel).toList();
  }

  // Watch all products (reactive)
  Stream<List<ProductModel>> watchAllProducts() {
    return _database.watchAllProducts().map(
          (products) => products.map(_toModel).toList(),
        );
  }

  // Get product by ID
  Future<ProductModel?> getProductById(int id) async {
    final product = await _database.getProductById(id);
    return product != null ? _toModel(product) : null;
  }

  // Search products
  Stream<List<ProductModel>> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _database.watchAllProducts().map(
          (products) => products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(lowerQuery) ||
                    (p.nameNepali?.toLowerCase().contains(lowerQuery) ?? false) ||
                    (p.barcode?.toLowerCase().contains(lowerQuery) ?? false) ||
                    (p.sku?.toLowerCase().contains(lowerQuery) ?? false),
              )
              .map(_toModel)
              .toList(),
        );
  }

  // Filter by category
  Stream<List<ProductModel>> filterByCategory(String category) {
    return _database.watchAllProducts().map(
          (products) => products
              .where((p) => p.category == category)
              .map(_toModel)
              .toList(),
        );
  }

  // Get low stock products
  Stream<List<ProductModel>> watchLowStockProducts() {
    return _database.watchAllProducts().map(
          (products) => products
              .where((p) => p.stock <= p.minStock && p.isActive)
              .map(_toModel)
              .toList(),
        );
  }

  // Insert product
  Future<int> insertProduct({
    required String name,
    String? nameNepali,
    String? description,
    String? barcode,
    String? sku,
    required double price,
    required double costPrice,
    required int stock,
    required int minStock,
    required String unit,
    String? category,
    String? imagePath,
    DateTime? expiryDate,
    bool expiryAlertEnabled = false,
    int expiryAlertDays = 7,
  }) async {
    return await _database.insertProduct(
      ProductsCompanion.insert(
        name: name,
        nameNepali: Value(nameNepali),
        description: Value(description),
        barcode: Value(barcode),
        sku: Value(sku),
        price: price,
        costPrice: Value(costPrice),
        stock: Value(stock),
        minStock: Value(minStock),
        unit: Value(unit),
        category: Value(category),
        imagePath: Value(imagePath),
        expiryDate: Value(expiryDate),
        expiryAlertEnabled: Value(expiryAlertEnabled),
        expiryAlertDays: Value(expiryAlertDays),
      ),
    );
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    return await _database.updateProduct(
      Product(
        id: product.id,
        name: product.name,
        nameNepali: product.nameNepali,
        description: product.description,
        barcode: product.barcode,
        sku: product.sku,
        price: product.price,
        costPrice: product.costPrice,
        stock: product.stock,
        minStock: product.minStock,
        unit: product.unit,
        category: product.category,
        imagePath: product.imagePath,
        expiryDate: product.expiryDate,
        expiryAlertEnabled: product.expiryAlertEnabled,
        expiryAlertDays: product.expiryAlertDays,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Delete product
  Future<int> deleteProduct(int id) async {
    return await _database.deleteProduct(id);
  }

  // Toggle active status
  Future<bool> toggleActiveStatus(int id, bool isActive) async {
    final product = await _database.getProductById(id);
    if (product == null) return false;

    return await _database.updateProduct(
      product.copyWith(isActive: isActive, updatedAt: DateTime.now()),
    );
  }

  // Update stock
  Future<bool> updateStock(int id, int newStock) async {
    final product = await _database.getProductById(id);
    if (product == null) return false;

    return await _database.updateProduct(
      product.copyWith(stock: newStock, updatedAt: DateTime.now()),
    );
  }

  // Get all categories
  Future<List<String>> getAllCategories() async {
    final products = await _database.getAllProducts();
    final categories = products
        .where((p) => p.category != null)
        .map((p) => p.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Convert Drift Product to ProductModel
  ProductModel _toModel(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      nameNepali: product.nameNepali,
      description: product.description,
      barcode: product.barcode,
      sku: product.sku,
      price: product.price,
      costPrice: product.costPrice,
      stock: product.stock,
      minStock: product.minStock,
      unit: product.unit,
      category: product.category,
      imagePath: product.imagePath,
      expiryDate: product.expiryDate,
      expiryAlertEnabled: product.expiryAlertEnabled,
      expiryAlertDays: product.expiryAlertDays,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }
}
