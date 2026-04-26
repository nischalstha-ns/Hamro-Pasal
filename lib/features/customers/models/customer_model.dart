import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_model.freezed.dart';
part 'customer_model.g.dart';

@freezed
class CustomerModel with _$CustomerModel {
  const factory CustomerModel({
    required int id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? panNumber,
    required double balance,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CustomerModel;

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
}

@freezed
class CustomerFormData with _$CustomerFormData {
  const factory CustomerFormData({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? panNumber,
    double? balance,
  }) = _CustomerFormData;
}
