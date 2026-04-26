import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required int id,
    required String invoiceNumber,
    required String type, // sale, purchase, payment, receipt, expense
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerPan,
    required double amount,
    required double vatAmount,
    required double totalAmount,
    required String paymentMethod,
    String? notes,
    String? attachments, // comma-separated file paths
    required DateTime transactionDate,
    required DateTime createdAt,
    @Default([]) List<TransactionItemModel> items,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}

@freezed
class TransactionItemModel with _$TransactionItemModel {
  const factory TransactionItemModel({
    required int id,
    required int transactionId,
    required int productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) = _TransactionItemModel;

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionItemModelFromJson(json);
}
