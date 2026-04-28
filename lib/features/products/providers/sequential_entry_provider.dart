import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/variant_model.dart';
import '../../settings/models/item_settings.dart';
import '../../settings/providers/item_settings_provider.dart';

enum SequentialStep {
  image,
  name,
  price,
  quantity,
  variants,
  sizes,
  colors,
  combinations,
  review,
}

class SequentialEntryState {
  final int currentStep;
  final int totalSteps;
  final String? imagePath;
  final String productName;
  final String? nameNepali;
  final double? sellingPrice;
  final double? costPrice;
  final int quantity;
  final String category;
  final String? description;
  final String? sku;
  final String? barcode;
  final bool enableVariants;
  final List<String> sizes;
  final List<ColorOption> colors;
  final List<VariantCombination> combinations;
  final Map<String, int> variantStock;
  final Map<String, double?> variantPrices;
  final String selectedUnit;
  final bool isComplete;
  final bool hasVariants;

  SequentialEntryState({
    this.currentStep = 0,
    this.totalSteps = 9,
    this.imagePath,
    this.productName = '',
    this.nameNepali,
    this.sellingPrice,
    this.costPrice,
    this.quantity = 0,
    this.category = '',
    this.description,
    this.sku,
    this.barcode,
    this.enableVariants = false,
    this.sizes = const [],
    this.colors = const [],
    this.combinations = const [],
    this.variantStock = const {},
    this.variantPrices = const {},
    this.selectedUnit = 'pcs',
    this.isComplete = false,
    this.hasVariants = false,
  });

  SequentialEntryState copyWith({
    int? currentStep,
    int? totalSteps,
    String? imagePath,
    String? productName,
    String? nameNepali,
    double? sellingPrice,
    double? costPrice,
    int? quantity,
    String? category,
    String? description,
    String? sku,
    String? barcode,
    bool? enableVariants,
    List<String>? sizes,
    List<ColorOption>? colors,
    List<VariantCombination>? combinations,
    Map<String, int>? variantStock,
    Map<String, double?>? variantPrices,
    String? selectedUnit,
    bool? isComplete,
    bool? hasVariants,
  }) {
    return SequentialEntryState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      imagePath: imagePath ?? this.imagePath,
      productName: productName ?? this.productName,
      nameNepali: nameNepali ?? this.nameNepali,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      enableVariants: enableVariants ?? this.enableVariants,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      combinations: combinations ?? this.combinations,
      variantStock: variantStock ?? this.variantStock,
      variantPrices: variantPrices ?? this.variantPrices,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      isComplete: isComplete ?? this.isComplete,
      hasVariants: hasVariants ?? this.hasVariants,
    );
  }

  int get calculatedTotalSteps {
    if (enableVariants) {
      return 10;
    }
    return 6;
  }

  String get stepTitle {
    switch (currentStep) {
      case 0:
        return 'Product Image';
      case 1:
        return 'Product Name';
      case 2:
        return 'Selling Price';
      case 3:
        return 'Quantity';
      case 4:
        return 'Variants';
      case 5:
        return 'Sizes';
      case 6:
        return 'Colors';
      case 7:
        return 'Combinations';
      case 8:
        return 'Review';
      default:
        return 'Step ${currentStep + 1}';
    }
  }

  String get stepDescription {
    switch (currentStep) {
      case 0:
        return 'Take or upload a photo of your product';
      case 1:
        return 'Enter the product name';
      case 2:
        return 'Set the selling price';
      case 3:
        return 'Enter stock quantity';
      case 4:
        return 'Does this product have variants?';
      case 5:
        return 'Add sizes (S, M, L or 28, 30, 32)';
      case 6:
        return 'Add colors for this product';
      case 7:
        return 'Review generated combinations';
      case 8:
        return 'Review and save your product';
      default:
        return '';
    }
  }
}

class SequentialEntryNotifier extends StateNotifier<SequentialEntryState> {
  final ItemSettings settings;

  SequentialEntryNotifier(this.settings)
      : super(SequentialEntryState());

  void setImage(String path) {
    state = state.copyWith(imagePath: path);
  }

  void setProductName(String name) {
    state = state.copyWith(productName: name);
  }

  void setSellingPrice(double price) {
    state = state.copyWith(sellingPrice: price);
    if (settings.autoSkuEnabled && state.sku == null) {
      state = state.copyWith(sku: _generateSku(state.productName, '', ''));
    }
    if (settings.autoBarcodeEnabled && state.barcode == null) {
      state = state.copyWith(barcode: _generateBarcode(state.productName, '', ''));
    }
  }

  void setCostPrice(double price) {
    state = state.copyWith(costPrice: price);
  }

  void setQuantity(int qty) {
    state = state.copyWith(quantity: qty);
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setUnit(String unit) {
    state = state.copyWith(selectedUnit: unit);
  }

  void setEnableVariants(bool enable) {
    state = state.copyWith(enableVariants: enable, hasVariants: enable);
  }

  void addSize(String size) {
    if (!state.sizes.contains(size)) {
      final newSizes = [...state.sizes, size];
      state = state.copyWith(sizes: newSizes);
      _updateCombinations();
    }
  }

  void removeSize(String size) {
    final newSizes = state.sizes.where((s) => s != size).toList();
    state = state.copyWith(sizes: newSizes);
    _updateCombinations();
  }

  void addColor(ColorOption color) {
    if (!state.colors.any((c) => c.hex == color.hex)) {
      final newColors = [...state.colors, color];
      state = state.copyWith(colors: newColors);
      _updateCombinations();
    }
  }

  void removeColor(ColorOption color) {
    final newColors = state.colors.where((c) => c.hex != color.hex).toList();
    state = state.copyWith(colors: newColors);
    _updateCombinations();
  }

  void setVariantStock(String key, int stock) {
    final newStock = Map<String, int>.from(state.variantStock);
    newStock[key] = stock;
    state = state.copyWith(variantStock: newStock);
  }

  void setVariantPrice(String key, double? price) {
    final newPrices = Map<String, double?>.from(state.variantPrices);
    newPrices[key] = price;
    state = state.copyWith(variantPrices: newPrices);
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.calculatedTotalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    goToStep(state.currentStep + 1);
  }

  void previousStep() {
    goToStep(state.currentStep - 1);
  }

  void _updateCombinations() {
    if (state.sizes.isNotEmpty && state.colors.isNotEmpty) {
      final combinations = VariantHelper.generateCombinations(
        sizes: state.sizes,
        colors: state.colors,
      );
      state = state.copyWith(combinations: combinations);
    } else {
      state = state.copyWith(combinations: []);
    }
  }

  String _generateBarcode(String name, String size, String color) {
    return VariantHelper.generateBarcode(name, size, color);
  }

  String _generateSku(String name, String size, String color) {
    return VariantHelper.generateSku(name, size, color);
  }

  void complete() {
    state = state.copyWith(isComplete: true);
  }

  void reset() {
    state = SequentialEntryState();
  }
}

final sequentialEntryProvider =
    StateNotifierProvider.autoDispose<SequentialEntryNotifier, SequentialEntryState>((ref) {
  final settingsAsync = ref.watch(itemSettingsProvider);
  final settings = settingsAsync.valueOrNull ?? ItemSettings.defaults();
  return SequentialEntryNotifier(settings);
});