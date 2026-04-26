import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/providers/products_provider.dart';
import '../models/item_settings.dart';

final itemSettingsProvider =
    AsyncNotifierProvider<ItemSettingsNotifier, ItemSettings>(
  ItemSettingsNotifier.new,
);

class ItemSettingsNotifier extends AsyncNotifier<ItemSettings> {
  static const _kEnableItem = 'item.enable';
  static const _kAllowServices = 'item.allowServices';
  static const _kBarcodeScan = 'item.barcodeScan';
  static const _kStockMaintenance = 'item.stockMaintenance';
  static const _kManufacturing = 'item.manufacturing';
  static const _kItemUnits = 'item.itemUnits';
  static const _kDefaultUnit = 'item.defaultUnit';
  static const _kItemCategory = 'item.itemCategory';
  static const _kDescription = 'item.description';
  static const _kPartyWiseRate = 'item.partyWiseItemRate';
  static const _kWholesalePrice = 'item.wholesalePrice';
  static const _kDecimalPlaces = 'item.decimalPlaces';
  static const _kItemWiseTax = 'item.itemWiseTax';
  static const _kItemWiseDiscount = 'item.itemWiseDiscount';
  static const _kUpdateSalePriceFromTxn = 'item.updateSalePriceFromTxn';

  @override
  Future<ItemSettings> build() async {
    final db = ref.watch(appDatabaseProvider);
    final defaults = ItemSettings.defaults();

    Future<bool> readBool(String key, bool fallback) async {
      final raw = await db.getSetting(key);
      if (raw == null) return fallback;
      return raw == '1' || raw.toLowerCase() == 'true';
    }

    Future<int> readInt(String key, int fallback) async {
      final raw = await db.getSetting(key);
      return int.tryParse(raw ?? '') ?? fallback;
    }

    Future<String> readString(String key, String fallback) async {
      final raw = await db.getSetting(key);
      return (raw == null || raw.isEmpty) ? fallback : raw;
    }

    return ItemSettings(
      enableItem: await readBool(_kEnableItem, defaults.enableItem),
      allowServices: await readBool(_kAllowServices, defaults.allowServices),
      barcodeScanEnabled:
          await readBool(_kBarcodeScan, defaults.barcodeScanEnabled),
      stockMaintenanceEnabled:
          await readBool(_kStockMaintenance, defaults.stockMaintenanceEnabled),
      manufacturingEnabled:
          await readBool(_kManufacturing, defaults.manufacturingEnabled),
      itemUnitsEnabled: await readBool(_kItemUnits, defaults.itemUnitsEnabled),
      defaultUnit: await readString(_kDefaultUnit, defaults.defaultUnit),
      itemCategoryEnabled:
          await readBool(_kItemCategory, defaults.itemCategoryEnabled),
      descriptionEnabled:
          await readBool(_kDescription, defaults.descriptionEnabled),
      partyWiseItemRateEnabled:
          await readBool(_kPartyWiseRate, defaults.partyWiseItemRateEnabled),
      wholesalePriceEnabled:
          await readBool(_kWholesalePrice, defaults.wholesalePriceEnabled),
      decimalPlaces: await readInt(_kDecimalPlaces, defaults.decimalPlaces),
      itemWiseTaxEnabled:
          await readBool(_kItemWiseTax, defaults.itemWiseTaxEnabled),
      itemWiseDiscountEnabled:
          await readBool(_kItemWiseDiscount, defaults.itemWiseDiscountEnabled),
      updateSalePriceFromTxnEnabled: await readBool(
        _kUpdateSalePriceFromTxn,
        defaults.updateSalePriceFromTxnEnabled,
      ),
    );
  }

  Future<void> _writeBool(String key, bool value) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting(key, value ? '1' : '0');
  }

  Future<void> _writeInt(String key, int value) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting(key, value.toString());
  }

  Future<void> _writeString(String key, String value) async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting(key, value);
  }

  Future<void> setEnableItem(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(enableItem: value));
    await _writeBool(_kEnableItem, value);
  }

  Future<void> setAllowServices(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(allowServices: value));
    await _writeBool(_kAllowServices, value);
  }

  Future<void> setBarcodeScanEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(barcodeScanEnabled: value));
    await _writeBool(_kBarcodeScan, value);
  }

  Future<void> setStockMaintenanceEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(stockMaintenanceEnabled: value));
    await _writeBool(_kStockMaintenance, value);
  }

  Future<void> setManufacturingEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(manufacturingEnabled: value));
    await _writeBool(_kManufacturing, value);
  }

  Future<void> setItemUnitsEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(itemUnitsEnabled: value));
    await _writeBool(_kItemUnits, value);
  }

  Future<void> setDefaultUnit(String value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(defaultUnit: value));
    await _writeString(_kDefaultUnit, value);
  }

  Future<void> setItemCategoryEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(itemCategoryEnabled: value));
    await _writeBool(_kItemCategory, value);
  }

  Future<void> setDescriptionEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(descriptionEnabled: value));
    await _writeBool(_kDescription, value);
  }

  Future<void> setPartyWiseItemRateEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(partyWiseItemRateEnabled: value));
    await _writeBool(_kPartyWiseRate, value);
  }

  Future<void> setWholesalePriceEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(wholesalePriceEnabled: value));
    await _writeBool(_kWholesalePrice, value);
  }

  Future<void> setDecimalPlaces(int value) async {
    final clamped = value.clamp(0, 4);
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(decimalPlaces: clamped));
    await _writeInt(_kDecimalPlaces, clamped);
  }

  Future<void> setItemWiseTaxEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(itemWiseTaxEnabled: value));
    await _writeBool(_kItemWiseTax, value);
  }

  Future<void> setItemWiseDiscountEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(itemWiseDiscountEnabled: value));
    await _writeBool(_kItemWiseDiscount, value);
  }

  Future<void> setUpdateSalePriceFromTxnEnabled(bool value) async {
    final current = state.valueOrNull ?? ItemSettings.defaults();
    state = AsyncData(current.copyWith(updateSalePriceFromTxnEnabled: value));
    await _writeBool(_kUpdateSalePriceFromTxn, value);
  }
}

