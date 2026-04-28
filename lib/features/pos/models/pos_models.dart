import 'package:freezed_annotation/freezed_annotation.dart';
import '../../products/models/product_model.dart';
import '../../customers/models/customer_model.dart';

part 'pos_models.freezed.dart';
part 'pos_models.g.dart';

@freezed
class PosCartItem with _$PosCartItem {
  const factory PosCartItem({
    required ProductModel product,
    required int quantity,
    String? selectedVariant, // e.g. "Size: M"
    @Default(0.0) double itemDiscount,
  }) = _PosCartItem;

  factory PosCartItem.fromJson(Map<String, dynamic> json) => _$PosCartItemFromJson(json);
}

extension PosCartItemExt on PosCartItem {
  double get unitPrice => product.price;
  double get totalPrice => (product.price * quantity) - itemDiscount;
}

@freezed
class PosCartState with _$PosCartState {
  const factory PosCartState({
    @Default([]) List<PosCartItem> items,
    CustomerModel? selectedCustomer,
    @Default(0.0) double globalDiscount,
    @Default(true) bool isPercentageDiscount,
    @Default(0.13) double taxRate,
    @Default('Cash') String paymentMethod,
    @Default('') String notes,
  }) = _PosCartState;

  factory PosCartState.fromJson(Map<String, dynamic> json) => _$PosCartStateFromJson(json);
}

extension PosCartStateExt on PosCartState {
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get calculatedDiscount {
    if (isPercentageDiscount) {
      return subtotal * (globalDiscount / 100);
    }
    return globalDiscount;
  }
  
  double get taxAmount => (subtotal - calculatedDiscount) * taxRate;
  
  double get total => subtotal - calculatedDiscount + taxAmount;
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
