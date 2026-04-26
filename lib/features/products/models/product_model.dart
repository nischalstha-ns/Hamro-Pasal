import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required int id,
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
    required bool expiryAlertEnabled,
    required int expiryAlertDays,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}

@freezed
class ProductFormData with _$ProductFormData {
  const factory ProductFormData({
    String? name,
    String? nameNepali,
    String? description,
    String? barcode,
    String? sku,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? unit,
    String? category,
    String? imagePath,
  }) = _ProductFormData;
}
