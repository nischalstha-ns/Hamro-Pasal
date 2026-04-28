import 'dart:convert';
import 'package:flutter/material.dart';

class ProductVariant {
  final int? id;
  final int productId;
  final String name;
  final String? size;
  final String? colorHex;
  final String? colorName;
  final double? priceOverride;
  final int? stock;
  final String? barcode;
  final String? sku;
  final bool isActive;

  ProductVariant({
    this.id,
    required this.productId,
    required this.name,
    this.size,
    this.colorHex,
    this.colorName,
    this.priceOverride,
    this.stock,
    this.barcode,
    this.sku,
    this.isActive = true,
  });

  ProductVariant copyWith({
    int? id,
    int? productId,
    String? name,
    String? size,
    String? colorHex,
    String? colorName,
    double? priceOverride,
    int? stock,
    String? barcode,
    String? sku,
    bool? isActive,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      size: size ?? this.size,
      colorHex: colorHex ?? this.colorHex,
      colorName: colorName ?? this.colorName,
      priceOverride: priceOverride ?? this.priceOverride,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
    );
  }

  String get displayName {
    final parts = <String>[];
    if (size != null && size!.isNotEmpty) parts.add(size!);
    if (colorName != null && colorName!.isNotEmpty) parts.add(colorName!);
    return parts.isEmpty ? name : parts.join(' - ');
  }
}

class VariantCombination {
  String size;
  String colorHex;
  String? colorName;
  double? price;
  int? stock;
  String? barcode;
  String? sku;

  VariantCombination({
    required this.size,
    required this.colorHex,
    this.colorName,
    this.price,
    this.stock,
    this.barcode,
    this.sku,
  });
}

class VariantHelper {
  static List<VariantCombination> generateCombinations({
    required List<String> sizes,
    required List<ColorOption> colors,
  }) {
    final combinations = <VariantCombination>[];
    for (final size in sizes) {
      for (final color in colors) {
        combinations.add(VariantCombination(
          size: size,
          colorHex: color.hex,
          colorName: color.name,
        ));
      }
    }
    return combinations;
  }

  static String generateBarcode(String productName, String size, String colorHex) {
    final hash = (productName + size + colorHex).hashCode.abs();
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'VP${hash.toString().padLeft(6, '0')}$timestamp';
  }

  static String generateSku(String productName, String size, String color) {
    final namePrefix = productName
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toUpperCase()
        .substring(0, productName.length.clamp(0, 3));
    final sizeCode = size.substring(0, size.length.clamp(0, 2)).toUpperCase();
    final colorCode = color.substring(0, color.length.clamp(0, 2)).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    return '$namePrefix-$sizeCode$colorCode-$timestamp';
  }

  static String encodeVariantOptions(Map<String, List<String>> variants) {
    return jsonEncode(variants);
  }

  static Map<String, List<String>> decodeVariantOptions(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
    } catch (_) {
      return {};
    }
  }
}

class ColorOption {
  final String hex;
  final String name;
  final int colorValue;

  const ColorOption({
    required this.hex,
    required this.name,
  }) : colorValue = 0xFF000000;

  factory ColorOption.fromHex(String hex, String name) {
    final colorValue = int.tryParse('FF$hex', radix: 16) ?? 0xFF000000;
    return ColorOption._(hex: hex, name: name, colorValue: colorValue);
  }

  const ColorOption._({
    required this.hex,
    required this.name,
    required this.colorValue,
  });

  Color get color => Color(colorValue);
}

final predefinedColors = <ColorOption>[
  const ColorOption(hex: '000000', name: 'Black'),
  const ColorOption(hex: 'FFFFFF', name: 'White'),
  const ColorOption(hex: '808080', name: 'Gray'),
  const ColorOption(hex: '000080', name: 'Navy'),
  const ColorOption(hex: '0000FF', name: 'Blue'),
  const ColorOption(hex: '0080FF', name: 'Sky Blue'),
  const ColorOption(hex: '00FFFF', name: 'Cyan'),
  const ColorOption(hex: '00FF00', name: 'Green'),
  const ColorOption(hex: '80FF00', name: 'Lime'),
  const ColorOption(hex: 'FFFF00', name: 'Yellow'),
  const ColorOption(hex: 'FF8000', name: 'Orange'),
  const ColorOption(hex: 'FF0000', name: 'Red'),
  const ColorOption(hex: 'FF0080', name: 'Pink'),
  const ColorOption(hex: 'FF00FF', name: 'Magenta'),
  const ColorOption(hex: '8000FF', name: 'Purple'),
  const ColorOption(hex: '8B4513', name: 'Brown'),
  const ColorOption(hex: 'FFD700', name: 'Gold'),
  const ColorOption(hex: 'C0C0C0', name: 'Silver'),
];

final clothingSizePresets = <String>[
  'XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL'
];

final shirtSizePresets = <String>[
  '30', '32', '34', '36', '38', '40', '42', '44'
];

final jeansSizePresets = <String>[
  '28', '30', '32', '34', '36', '38', '40'
];

final shoeSizePresetsUSMen = <String>[
  '6', '7', '8', '9', '10', '11', '12', '13'
];

final shoeSizePresetsUSWomen = <String>[
  '5', '6', '7', '8', '9', '10', '11'
];

final shoeSizePresetsEU = <String>[
  '38', '39', '40', '41', '42', '43', '44', '45'
];

final kidsSizePresets = <String>[
  '2-3Y', '4-5Y', '6-7Y', '8-9Y', '10-11Y', '12-13Y'
];