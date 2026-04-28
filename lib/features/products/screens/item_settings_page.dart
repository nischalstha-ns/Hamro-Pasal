import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/models/item_settings.dart';
import '../../settings/providers/item_settings_provider.dart';

class ItemSettingsPage extends ConsumerWidget {
  const ItemSettingsPage({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(itemSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? ItemSettings.defaults();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            value: settings.enableItem,
            onChanged: (v) =>
                ref.read(itemSettingsProvider.notifier).setEnableItem(v),
            title: const Text('Enable Item'),
            secondary: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Item Type'),
            subtitle: Text(
              settings.allowServices ? 'Products and Services' : 'Products',
            ),
            trailing: const Icon(Icons.keyboard_arrow_down),
            onTap: () async {
              final selection = await showModalBottomSheet<bool>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return SafeArea(
                    child: ListView(
                      children: [
                        ListTile(
                          title: const Text('Products and Services'),
                          trailing: settings.allowServices
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.pop(context, true),
                        ),
                        ListTile(
                          title: const Text('Products'),
                          trailing: !settings.allowServices
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                  );
                },
              );
              if (selection != null) {
                await ref
                    .read(itemSettingsProvider.notifier)
                    .setAllowServices(selection);
              }
            },
          ),
          SwitchListTile(
            value: settings.barcodeScanEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setBarcodeScanEnabled(v),
            title: const Text('Barcode scanning for items'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.stockMaintenanceEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setStockMaintenanceEnabled(v),
            title: const Text('Stock maintenance'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.manufacturingEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setManufacturingEnabled(v),
            title: const Text('Manufacturing'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.itemUnitsEnabled,
            onChanged: (v) =>
                ref.read(itemSettingsProvider.notifier).setItemUnitsEnabled(v),
            title: const Text('Item Units'),
            secondary: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Default Unit'),
            trailing: const Icon(Icons.keyboard_arrow_down),
            subtitle: Text(settings.defaultUnit),
            onTap: settings.itemUnitsEnabled
                ? () async {
                    const units = [
                      'pcs',
                      'kg',
                      'g',
                      'l',
                      'ml',
                      'box',
                      'pack',
                      'dozen',
                    ];
                    final unit = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) {
                        return SafeArea(
                          child: ListView(
                            children: [
                              for (final u in units)
                                ListTile(
                                  title: Text(u),
                                  trailing: u == settings.defaultUnit
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () => Navigator.pop(context, u),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                    if (unit != null) {
                      await ref
                          .read(itemSettingsProvider.notifier)
                          .setDefaultUnit(unit);
                    }
                  }
                : null,
          ),
          SwitchListTile(
            value: settings.itemCategoryEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setItemCategoryEnabled(v),
            title: const Text('Item Category'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.partyWiseItemRateEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setPartyWiseItemRateEnabled(v),
            title: const Text('Party wise item rate'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.wholesalePriceEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setWholesalePriceEnabled(v),
            title: const Text('Wholesale Price'),
            secondary: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Quantity (Upto Decimal places)'),
            subtitle: Text(settings.decimalPlaces.toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(itemSettingsProvider.notifier)
                      .setDecimalPlaces(settings.decimalPlaces - 1),
                  icon: const Icon(Icons.remove),
                ),
                Text(settings.decimalPlaces.toString()),
                IconButton(
                  onPressed: () => ref
                      .read(itemSettingsProvider.notifier)
                      .setDecimalPlaces(settings.decimalPlaces + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            onTap: () async {
              final selected = await showModalBottomSheet<int>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return SafeArea(
                    child: ListView(
                      children: [
                        for (int i = 0; i <= 4; i++)
                          ListTile(
                            title: Text(i.toString()),
                            trailing: settings.decimalPlaces == i
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.pop(context, i),
                          ),
                      ],
                    ),
                  );
                },
              );
              if (selected != null) {
                await ref
                    .read(itemSettingsProvider.notifier)
                    .setDecimalPlaces(selected);
              }
            },
          ),
          SwitchListTile(
            value: settings.itemWiseTaxEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setItemWiseTaxEnabled(v),
            title: const Text('Item wise tax'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.itemWiseDiscountEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setItemWiseDiscountEnabled(v),
            title: const Text('Item wise discount'),
            secondary: const Icon(Icons.info_outline),
          ),
          SwitchListTile(
            value: settings.updateSalePriceFromTxnEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setUpdateSalePriceFromTxnEnabled(v),
            title: const Text('Update Sale Price from TXN'),
            secondary: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Additional Item Fields'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMessage(context, 'Coming soon'),
          ),
          ListTile(
            title: const Text('Item Custom Fields'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMessage(context, 'Coming soon'),
          ),
          SwitchListTile(
            value: settings.descriptionEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setDescriptionEnabled(v),
            title: const Text('Description'),
            secondary: const Icon(Icons.info_outline),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Smart Entry',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SwitchListTile(
            value: settings.sequentialEntryEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setSequentialEntryEnabled(v),
            title: const Text('Sequential Entry Mode'),
            subtitle: const Text('Step-by-step guided input for fast entry'),
            secondary: const Icon(Icons.format_list_numbered),
          ),
          SwitchListTile(
            value: settings.quickVariantEntryEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setQuickVariantEntryEnabled(v),
            title: const Text('Quick Variant Entry'),
            subtitle: const Text('Fast variant selection with templates'),
            secondary: const Icon(Icons.style),
          ),
          SwitchListTile(
            value: settings.autoBarcodeEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setAutoBarcodeEnabled(v),
            title: const Text('Auto Barcode'),
            subtitle: const Text('Generate barcode automatically'),
            secondary: const Icon(Icons.qr_code),
          ),
          SwitchListTile(
            value: settings.autoSkuEnabled,
            onChanged: (v) => ref
                .read(itemSettingsProvider.notifier)
                .setAutoSkuEnabled(v),
            title: const Text('Auto SKU'),
            subtitle: const Text('Generate SKU automatically'),
            secondary: const Icon(Icons.tag),
          ),
        ],
      ),
    );
  }
}
