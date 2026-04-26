import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/connection.dart';
import '../../../core/database/app_database.dart';
import '../models/product_model.dart';
import '../repositories/products_repository.dart';

part 'products_provider.g.dart';

// Database provider — must be kept alive for the app's lifetime
// so streams don't break on navigation
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
}

// Repository provider
@riverpod
ProductsRepository productsRepository(ProductsRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProductsRepository(database);
}

// All products stream provider
@riverpod
Stream<List<ProductModel>> productsStream(ProductsStreamRef ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.watchAllProducts();
}

// Low stock products provider
@riverpod
Stream<List<ProductModel>> lowStockProducts(LowStockProductsRef ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.watchLowStockProducts();
}

// Categories provider
@riverpod
Future<List<String>> productCategories(ProductCategoriesRef ref) async {
  final repository = ref.watch(productsRepositoryProvider);
  return await repository.getAllCategories();
}

// Search query provider
@riverpod
class ProductSearchQuery extends _$ProductSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

// Filtered products provider
@riverpod
Stream<List<ProductModel>> filteredProducts(FilteredProductsRef ref) {
  final repository = ref.watch(productsRepositoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);

  if (searchQuery.isEmpty) {
    return repository.watchAllProducts();
  }

  return repository.searchProducts(searchQuery);
}

// Selected category provider
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;

  void setCategory(String? category) {
    state = category;
  }

  void clear() {
    state = null;
  }
}

// Products by category provider
@riverpod
Stream<List<ProductModel>> productsByCategory(ProductsByCategoryRef ref) {
  final repository = ref.watch(productsRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  if (selectedCategory == null) {
    return repository.watchAllProducts();
  }

  return repository.filterByCategory(selectedCategory);
}

// Single product provider
@riverpod
Future<ProductModel?> product(ProductRef ref, int id) async {
  final repository = ref.watch(productsRepositoryProvider);
  return await repository.getProductById(id);
}

// Product actions provider
@riverpod
class ProductActions extends _$ProductActions {
  @override
  FutureOr<void> build() {}

  Future<int> addProduct({
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
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(productsRepositoryProvider);
      final id = await repository.insertProduct(
        name: name,
        nameNepali: nameNepali,
        description: description,
        barcode: barcode,
        sku: sku,
        price: price,
        costPrice: costPrice,
        stock: stock,
        minStock: minStock,
        unit: unit,
        category: category,
        imagePath: imagePath,
        expiryDate: expiryDate,
        expiryAlertEnabled: expiryAlertEnabled,
        expiryAlertDays: expiryAlertDays,
      );
      
      // Invalidate products list
      ref.invalidate(productsStreamProvider);
      ref.invalidate(productCategoriesProvider);
      
      return id;
    }).then((asyncValue) {
      state = asyncValue;
      return asyncValue.value ?? 0;
    });
  }

  Future<bool> updateProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(productsRepositoryProvider);
      final success = await repository.updateProduct(product);
      
      // Invalidate products list
      ref.invalidate(productsStreamProvider);
      ref.invalidate(productProvider(product.id));
      
      return success;
    }).then((asyncValue) {
      state = asyncValue;
      return asyncValue.value ?? false;
    });
  }

  Future<bool> deleteProduct(int id) async {
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(productsRepositoryProvider);
      final result = await repository.deleteProduct(id);
      
      // Invalidate products list
      ref.invalidate(productsStreamProvider);
      ref.invalidate(productCategoriesProvider);
      
      return result > 0;
    }).then((asyncValue) {
      state = asyncValue;
      return asyncValue.value ?? false;
    });
  }

  Future<bool> toggleActiveStatus(int id, bool isActive) async {
    final repository = ref.read(productsRepositoryProvider);
    final success = await repository.toggleActiveStatus(id, isActive);
    
    if (success) {
      ref.invalidate(productsStreamProvider);
      ref.invalidate(productProvider(id));
    }
    
    return success;
  }

  Future<bool> updateStock(int id, int newStock) async {
    final repository = ref.read(productsRepositoryProvider);
    final success = await repository.updateStock(id, newStock);
    
    if (success) {
      ref.invalidate(productsStreamProvider);
      ref.invalidate(productProvider(id));
    }
    
    return success;
  }
}
