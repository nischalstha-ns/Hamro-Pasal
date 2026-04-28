class ItemSettings {
  const ItemSettings({
    required this.enableItem,
    required this.allowServices,
    required this.barcodeScanEnabled,
    required this.stockMaintenanceEnabled,
    required this.manufacturingEnabled,
    required this.itemUnitsEnabled,
    required this.defaultUnit,
    required this.itemCategoryEnabled,
    required this.descriptionEnabled,
    required this.partyWiseItemRateEnabled,
    required this.wholesalePriceEnabled,
    required this.decimalPlaces,
    required this.itemWiseTaxEnabled,
    required this.itemWiseDiscountEnabled,
    required this.updateSalePriceFromTxnEnabled,
    required this.sequentialEntryEnabled,
    required this.quickVariantEntryEnabled,
    required this.autoBarcodeEnabled,
    required this.autoSkuEnabled,
  });

  factory ItemSettings.defaults() {
    return const ItemSettings(
      enableItem: true,
      allowServices: true,
      barcodeScanEnabled: true,
      stockMaintenanceEnabled: true,
      manufacturingEnabled: false,
      itemUnitsEnabled: true,
      defaultUnit: 'pcs',
      itemCategoryEnabled: true,
      descriptionEnabled: false,
      partyWiseItemRateEnabled: false,
      wholesalePriceEnabled: true,
      decimalPlaces: 2,
      itemWiseTaxEnabled: false,
      itemWiseDiscountEnabled: false,
      updateSalePriceFromTxnEnabled: false,
      sequentialEntryEnabled: true,
      quickVariantEntryEnabled: true,
      autoBarcodeEnabled: true,
      autoSkuEnabled: true,
    );
  }

  final bool enableItem;
  final bool allowServices;
  final bool barcodeScanEnabled;
  final bool stockMaintenanceEnabled;
  final bool manufacturingEnabled;
  final bool itemUnitsEnabled;
  final String defaultUnit;
  final bool itemCategoryEnabled;
  final bool descriptionEnabled;
  final bool partyWiseItemRateEnabled;
  final bool wholesalePriceEnabled;
  final int decimalPlaces;
  final bool itemWiseTaxEnabled;
  final bool itemWiseDiscountEnabled;
  final bool updateSalePriceFromTxnEnabled;
  final bool sequentialEntryEnabled;
  final bool quickVariantEntryEnabled;
  final bool autoBarcodeEnabled;
  final bool autoSkuEnabled;

  ItemSettings copyWith({
    bool? enableItem,
    bool? allowServices,
    bool? barcodeScanEnabled,
    bool? stockMaintenanceEnabled,
    bool? manufacturingEnabled,
    bool? itemUnitsEnabled,
    String? defaultUnit,
    bool? itemCategoryEnabled,
    bool? descriptionEnabled,
    bool? partyWiseItemRateEnabled,
    bool? wholesalePriceEnabled,
    int? decimalPlaces,
    bool? itemWiseTaxEnabled,
    bool? itemWiseDiscountEnabled,
    bool? updateSalePriceFromTxnEnabled,
    bool? sequentialEntryEnabled,
    bool? quickVariantEntryEnabled,
    bool? autoBarcodeEnabled,
    bool? autoSkuEnabled,
  }) {
    return ItemSettings(
      enableItem: enableItem ?? this.enableItem,
      allowServices: allowServices ?? this.allowServices,
      barcodeScanEnabled: barcodeScanEnabled ?? this.barcodeScanEnabled,
      stockMaintenanceEnabled:
          stockMaintenanceEnabled ?? this.stockMaintenanceEnabled,
      manufacturingEnabled: manufacturingEnabled ?? this.manufacturingEnabled,
      itemUnitsEnabled: itemUnitsEnabled ?? this.itemUnitsEnabled,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      itemCategoryEnabled: itemCategoryEnabled ?? this.itemCategoryEnabled,
      descriptionEnabled: descriptionEnabled ?? this.descriptionEnabled,
      partyWiseItemRateEnabled:
          partyWiseItemRateEnabled ?? this.partyWiseItemRateEnabled,
      wholesalePriceEnabled: wholesalePriceEnabled ?? this.wholesalePriceEnabled,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      itemWiseTaxEnabled: itemWiseTaxEnabled ?? this.itemWiseTaxEnabled,
      itemWiseDiscountEnabled:
          itemWiseDiscountEnabled ?? this.itemWiseDiscountEnabled,
      updateSalePriceFromTxnEnabled:
          updateSalePriceFromTxnEnabled ?? this.updateSalePriceFromTxnEnabled,
      sequentialEntryEnabled: sequentialEntryEnabled ?? this.sequentialEntryEnabled,
      quickVariantEntryEnabled: quickVariantEntryEnabled ?? this.quickVariantEntryEnabled,
      autoBarcodeEnabled: autoBarcodeEnabled ?? this.autoBarcodeEnabled,
      autoSkuEnabled: autoSkuEnabled ?? this.autoSkuEnabled,
    );
  }
}

