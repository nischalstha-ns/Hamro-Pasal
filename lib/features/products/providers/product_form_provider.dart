import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/product_model.dart';

part 'product_form_provider.g.dart';

@riverpod
class ProductFormState extends _$ProductFormState {
  @override
  ProductFormData build() {
    return const ProductFormData(
      unit: 'pcs',
      stock: 0,
      minStock: 0,
      price: 0.0,
      costPrice: 0.0,
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setNameNepali(String? nameNepali) {
    state = state.copyWith(nameNepali: nameNepali);
  }

  void setDescription(String? description) {
    state = state.copyWith(description: description);
  }

  void setBarcode(String? barcode) {
    state = state.copyWith(barcode: barcode);
  }

  void setSku(String? sku) {
    state = state.copyWith(sku: sku);
  }

  void setPrice(double price) {
    state = state.copyWith(price: price);
  }

  void setCostPrice(double costPrice) {
    state = state.copyWith(costPrice: costPrice);
  }

  void setStock(int stock) {
    state = state.copyWith(stock: stock);
  }

  void setMinStock(int minStock) {
    state = state.copyWith(minStock: minStock);
  }

  void setUnit(String unit) {
    state = state.copyWith(unit: unit);
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void setImagePath(String? imagePath) {
    state = state.copyWith(imagePath: imagePath);
  }

  void loadProduct(ProductModel product) {
    state = ProductFormData(
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
    );
  }

  void reset() {
    state = const ProductFormData(
      unit: 'pcs',
      stock: 0,
      minStock: 0,
      price: 0.0,
      costPrice: 0.0,
    );
  }
}
