import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/pos_models.dart';
import '../../products/models/product_model.dart';
import '../../customers/models/customer_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transactions_provider.dart';

part 'pos_provider.g.dart';

@riverpod
class PosCart extends _$PosCart {
  @override
  PosCartState build() {
    return const PosCartState();
  }

  void addItem(ProductModel product, {String? variant}) {
    final items = List<PosCartItem>.from(state.items);
    
    // Check if same product and variant already in cart
    final index = items.indexWhere((item) => 
      item.product.id == product.id && item.selectedVariant == variant);
    
    if (index != -1) {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + 1,
      );
    } else {
      items.add(PosCartItem(
        product: product,
        quantity: 1,
        selectedVariant: variant,
      ));
    }
    
    state = state.copyWith(items: items);
  }

  void removeItem(int index) {
    final items = List<PosCartItem>.from(state.items);
    items.removeAt(index);
    state = state.copyWith(items: items);
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final items = List<PosCartItem>.from(state.items);
    items[index] = items[index].copyWith(quantity: quantity);
    state = state.copyWith(items: items);
  }

  void setCustomer(CustomerModel? customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void setGlobalDiscount(double discount, bool isPercentage) {
    state = state.copyWith(
      globalDiscount: discount,
      isPercentageDiscount: isPercentage,
    );
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clearCart() {
    state = const PosCartState();
  }

  Future<int> checkout() async {
    if (state.items.isEmpty) return 0;

    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    
    final transaction = TransactionModel(
      id: 0, // Assigned by DB
      invoiceNumber: invoiceNumber,
      type: 'sale',
      customerId: state.selectedCustomer?.id,
      customerName: state.selectedCustomer?.name,
      customerPhone: state.selectedCustomer?.phone,
      customerAddress: state.selectedCustomer?.address,
      amount: state.subtotal,
      vatAmount: state.taxAmount,
      totalAmount: state.total,
      paymentMethod: state.paymentMethod,
      notes: state.notes,
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
      items: [], // Items are passed separately to addTransactionWithItems
    );

    final items = state.items.map((item) => TransactionItemModel(
      id: 0,
      transactionId: 0,
      productId: item.product.id,
      productName: item.product.name,
      quantity: item.quantity,
      unitPrice: item.product.price,
      totalPrice: item.totalPrice,
      selectedVariant: item.selectedVariant,
    )).toList();

    final resultId = await ref.read(transactionActionsProvider.notifier).addTransactionWithItems(
      transaction: transaction,
      items: items,
    );

    if (resultId > 0) {
      clearCart();
    }
    
    return resultId;
  }
}
