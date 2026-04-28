import 'dart:io';
import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/validators.dart';
import '../../settings/models/item_settings.dart';
import '../../settings/providers/item_settings_provider.dart';
import '../models/product_model.dart';
import '../providers/products_provider.dart';
import 'item_settings_page.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final ProductModel? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _asOfDateController = TextEditingController();
  final _atPricePerUnitController = TextEditingController();
  final _itemLocationController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _minWholesaleQtyController = TextEditingController();

  String? _imagePath;
  DateTime? _expiryDate;
  bool _expiryAlertEnabled = false;
  int _expiryAlertDays = 7;

  String _selectedUnit = 'pcs';
  bool _isLoading = false;
  bool _isService = false;
  int _selectedDetailsTab = 0;
  bool _showWholesale = false;
  bool _hasVariants = false;
  Map<String, List<String>> _variants = {};

  static const Map<String, List<String>> clothingSizes = {
    'Clothing': ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'Kids': ['2-3Y', '4-5Y', '6-7Y', '8-9Y', '10-11Y', '12-13Y'],
  };

  static const Map<String, List<String>> shoeSizes = {
    'US Men': ['6', '7', '8', '9', '10', '11', '12', '13'],
    'US Women': ['5', '6', '7', '8', '9', '10', '11'],
    'UK': ['5', '6', '7', '8', '9', '10', '11'],
    'EU': ['38', '39', '40', '41', '42', '43', '44', '45'],
  };

  static const Map<String, List<String>> apparelSizes = {
    'Shirt': ['30', '32', '34', '36', '38', '40', '42', '44'],
    'Jeans': ['28', '30', '32', '34', '36', '38'],
  };

  static const List<Color> predefinedColors = [
    Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFF808080),
    Color(0xFF000080), Color(0xFF0000FF), Color(0xFF0080FF),
    Color(0xFF00FFFF), Color(0xFF00FF00), Color(0xFF80FF00),
    Color(0xFFFFFF00), Color(0xFFFF8000), Color(0xFFFF0000),
    Color(0xFFFF0080), Color(0xFFFF00FF), Color(0xFF8000FF),
    Color(0xFF8B4513), Color(0xFFFFD700), Color(0xFFC0C0C0),
  ];

  static const Map<String, String> colorNames = {
    'FF000000': 'Black', 'FFFFFFFF': 'White', 'FF808080': 'Gray',
    'FF000080': 'Navy', 'FF0000FF': 'Blue', 'FF0080FF': 'Sky Blue',
    'FF00FFFF': 'Cyan', 'FF00FF00': 'Green', 'FF80FF00': 'Lime',
    'FFFFFF00': 'Yellow', 'FFFF8000': 'Orange', 'FFFF0000': 'Red',
    'FFFF0080': 'Pink', 'FFFF00FF': 'Magenta', 'FF8000FF': 'Purple',
    'FF8B4513': 'Brown', 'FFFFD700': 'Gold', 'FFC0C0C0': 'Silver',
  };

  final List<String> _units = [
    'pcs',
    'kg',
    'g',
    'l',
    'ml',
    'box',
    'pack',
    'dozen',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProduct(widget.product!);
    }
    _asOfDateController.text = '11-Chaitra-2082';
    if (widget.product == null) {
      Future.microtask(() async {
        final settings = await ref.read(itemSettingsProvider.future);
        if (!mounted) return;
        if (_selectedUnit == 'pcs' && settings.defaultUnit != 'pcs') {
          setState(() => _selectedUnit = settings.defaultUnit);
        }
      });
    }
  }

  void _loadProduct(ProductModel product) {
    _nameController.text = product.name;
    _barcodeController.text = product.barcode ?? '';
    _priceController.text = product.price.toString();
    _costPriceController.text = product.costPrice.toString();
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _categoryController.text = product.category ?? '';
    _selectedUnit = product.unit;
    _imagePath = product.imagePath;
    _expiryDate = product.expiryDate;
    _expiryAlertEnabled = product.expiryAlertEnabled;
    _expiryAlertDays = product.expiryAlertDays;
    
    _hasVariants = product.hasVariants;
    if (product.variantOptions != null && product.variantOptions!.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(product.variantOptions!);
        _variants = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      } catch (_) {
        _variants = {};
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _categoryController.dispose();
    _asOfDateController.dispose();
    _atPricePerUnitController.dispose();
    _itemLocationController.dispose();
    _wholesalePriceController.dispose();
    _minWholesaleQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final itemSettingsAsync = ref.watch(itemSettingsProvider);
    final itemSettings =
        itemSettingsAsync.valueOrNull ?? ItemSettings.defaults();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Item' : 'Add Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (!isEdit && itemSettings.sequentialEntryEnabled)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/product/add/quick');
              },
              icon: const Icon(Icons.flash_on),
              tooltip: 'Quick Entry',
            ),
          IconButton(
            onPressed: _isLoading ? null : _showImagePickerOptions,
            icon: const Icon(Icons.photo_camera_outlined),
          ),
          IconButton(
            onPressed: _isLoading ? null : _openItemSettingsSheet,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE21B22),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                (constraints.maxWidth * 0.05).clamp(12.0, 24.0);
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                bottomInset + 24,
              ),
              children: [
                if (_imagePath != null) ...[
                  _buildImagePreview(),
                  const SizedBox(height: 12),
                ],
                _buildTypeToggle(context, itemSettings),
                const SizedBox(height: 12),
                _buildNameField(context),
                const SizedBox(height: 12),
                _buildCodeField(context, itemSettings),
                const SizedBox(height: 12),
                if (itemSettings.itemCategoryEnabled) ...[
                  categoriesAsync.when(
                    data: (categories) => _buildCategoryField(
                      context,
                      categories: categories,
                    ),
                    loading: () =>
                        _buildCategoryField(context, categories: const []),
                    error: (_, __) =>
                        _buildCategoryField(context, categories: const []),
                  ),
                  const SizedBox(height: 12),
                ],
                if (itemSettings.descriptionEnabled) ...[
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                ],
                if (itemSettings.stockMaintenanceEnabled) ...[
                  _buildDetailsTabs(context, itemSettings),
                  const SizedBox(height: 12),
                ],
                if (!itemSettings.stockMaintenanceEnabled ||
                    _selectedDetailsTab == 0 ||
                    _isService)
                  _buildPricing(context, itemSettings),
                if (itemSettings.stockMaintenanceEnabled &&
                    _selectedDetailsTab == 1 &&
                    !_isService)
                  _buildStock(context),
                const SizedBox(height: 12),
                _buildVariantsSection(context),
                const SizedBox(height: 12),
                _buildExpirySection(context),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context, ItemSettings settings) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final allowServices = settings.allowServices;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Product',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isService ? inactiveColor : activeColor,
                ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _isService,
            onChanged: (!allowServices || _isLoading)
                ? null
                : (value) {
                    setState(() {
                      _isService = value;
                      if (_isService && _selectedDetailsTab == 1) {
                        _selectedDetailsTab = 0;
                      }
                    });
                  },
          ),
          const SizedBox(width: 12),
          Text(
            'Services',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isService ? activeColor : inactiveColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTabs(BuildContext context, ItemSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedDetailsTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedDetailsTab == 0
                          ? const Color(0xFFE21B22)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Pricing',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _selectedDetailsTab == 0
                              ? const Color(0xFFE21B22)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: (_isService || !settings.stockMaintenanceEnabled)
                  ? null
                  : () => setState(() => _selectedDetailsTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: (!_isService &&
                              settings.stockMaintenanceEnabled &&
                              _selectedDetailsTab == 1)
                          ? const Color(0xFFE21B22)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Stock',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              (_isService || !settings.stockMaintenanceEnabled)
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.6)
                                  : (_selectedDetailsTab == 1
                                      ? const Color(0xFFE21B22)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Item Name *',
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 8, 8),
          child: FilledButton.tonal(
            onPressed: _isLoading ? null : () => _pickUnit(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(_selectedUnit == 'pcs' ? 'Select Unit' : _selectedUnit),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minHeight: 40),
      ),
      validator: (value) => Validators.requiredField(value, fieldName: 'Item name'),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildCodeField(BuildContext context, ItemSettings settings) {
    return TextFormField(
      controller: _barcodeController,
      decoration: InputDecoration(
        labelText: 'Item Code / Barcode',
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 8, 8),
          child: FilledButton.tonal(
            onPressed: _isLoading || !settings.barcodeScanEnabled
                ? null
                : () {
                    if (_barcodeController.text.trim().isEmpty) {
                      _barcodeController.text =
                          DateTime.now().millisecondsSinceEpoch.toString();
                    }
                  },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Assign Code'),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minHeight: 40),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildCategoryField(
    BuildContext context, {
    required List<String> categories,
  }) {
    return TextFormField(
      controller: _categoryController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Item Category',
        suffixIcon: Icon(Icons.keyboard_arrow_down),
      ),
      onTap: _isLoading ? null : () => _pickCategory(context, categories),
    );
  }

  Widget _buildPricing(BuildContext context, ItemSettings settings) {
    final sectionTitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final allowWholesale = settings.wholesalePriceEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sale Price', style: sectionTitleStyle),
        const SizedBox(height: 10),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            hintText: 'Sale Price',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => Validators.positiveNumber(
            value,
            fieldName: 'Sale price',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        if (allowWholesale)
          if (!_showWholesale)
            TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _showWholesale = true),
              icon: const Icon(Icons.add),
              label: const Text('Add Wholesale Price'),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Wholesale Price', style: sectionTitleStyle),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _showWholesale = false);
                              _wholesalePriceController.clear();
                              _minWholesaleQtyController.clear();
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _wholesalePriceController,
                  decoration: const InputDecoration(
                    hintText: 'Wholesale Price',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minWholesaleQtyController,
                  decoration: const InputDecoration(
                    hintText: 'Min Wholesale Qty',
                    suffixIcon: Icon(Icons.info_outline),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],
            ),
        const SizedBox(height: 6),
        Text('Purchase Price', style: sectionTitleStyle),
        const SizedBox(height: 10),
        TextFormField(
          controller: _costPriceController,
          decoration: const InputDecoration(
            hintText: 'Purchase Price',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return Validators.positiveNumber(
                value,
                fieldName: 'Purchase price',
              );
            }
            return null;
          },
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildStock(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Opening Stock', style: labelStyle),
        const SizedBox(height: 10),
        TextFormField(
          controller: _stockController,
          decoration: const InputDecoration(
            hintText: 'Ex: 300',
          ),
          keyboardType: TextInputType.number,
          validator: (value) => Validators.number(value, fieldName: 'Stock'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _asOfDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'As of Date',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                onTap: _isLoading ? null : () => _pickDate(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _atPricePerUnitController,
                decoration: const InputDecoration(
                  labelText: 'At Price/Unit',
                  hintText: 'Ex: 2,000',
                  suffixIcon: Icon(Icons.info_outline),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Min Stock Qty',
                  hintText: 'Ex: 5',
                  suffixIcon: Icon(Icons.info_outline),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.number(value, fieldName: 'Min stock'),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _itemLocationController,
                decoration: const InputDecoration(
                  labelText: 'Item Location',
                ),
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openItemSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final settingsAsync = ref.watch(itemSettingsProvider);
            final settings =
                settingsAsync.valueOrNull ?? ItemSettings.defaults();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Item Custom Fields'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemSettingsPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Additional Item Fields'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemSettingsPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      value: settings.wholesalePriceEnabled,
                      onChanged: (v) async {
                        if (!v) {
                          setState(() => _showWholesale = false);
                        }
                        await ref
                            .read(itemSettingsProvider.notifier)
                            .setWholesalePriceEnabled(v);
                      },
                      title: const Text('Wholesale Price'),
                    ),
                    SwitchListTile(
                      value: settings.barcodeScanEnabled,
                      onChanged: (v) => ref
                          .read(itemSettingsProvider.notifier)
                          .setBarcodeScanEnabled(v),
                      title: const Text('Barcode Scan'),
                    ),
                    SwitchListTile(
                      value: settings.itemCategoryEnabled,
                      onChanged: (v) => ref
                          .read(itemSettingsProvider.notifier)
                          .setItemCategoryEnabled(v),
                      title: const Text('Item Category'),
                    ),
                    SwitchListTile(
                      value: settings.descriptionEnabled,
                      onChanged: (v) => ref
                          .read(itemSettingsProvider.notifier)
                          .setDescriptionEnabled(v),
                      title: const Text('Description'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ItemSettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('More Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickUnit(BuildContext context) async {
    final unit = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              for (final u in _units)
                ListTile(
                  title: Text(u),
                  trailing: u == _selectedUnit ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, u),
                ),
            ],
          ),
        );
      },
    );
    if (unit != null) {
      setState(() => _selectedUnit = unit);
    }
  }

  Future<void> _pickCategory(
    BuildContext context,
    List<String> categories,
  ) async {
    final options = categories.toSet().toList()..sort();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: const Text('Add new category'),
                leading: const Icon(Icons.add),
                onTap: () async {
                  Navigator.pop(context);
                  final text = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add Category'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, controller.text.trim()),
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                  if (text != null && text.isNotEmpty) {
                    _categoryController.text = text;
                  }
                },
              ),
              if (options.isNotEmpty) const Divider(height: 1),
              for (final category in options)
                ListTile(
                  title: Text(category),
                  trailing: _categoryController.text == category
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, category),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      _categoryController.text = selected;
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );
    if (picked != null) {
      _asOfDateController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: _imagePath != null && File(_imagePath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.image, size: 48, color: Colors.grey),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => setState(() => _imagePath = null),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expiry Settings',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Switch(
              value: _expiryAlertEnabled,
              onChanged: (v) => setState(() => _expiryAlertEnabled = v),
            ),
          ],
        ),
        if (_expiryAlertEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  controller: TextEditingController(
                    text: _expiryDate != null
                        ? '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'
                        : '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() => _expiryDate = date);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: _expiryAlertDays.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Alert Days',
                    suffixText: 'days',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _expiryAlertDays = int.tryParse(v) ?? 7,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVariantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hasVariants ? const Color(0xFFF5F5FF) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasVariants ? const Color(0xFF3D8BFF) : Colors.grey[300]!,
              width: _hasVariants ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.style,
                        color: _hasVariants
                            ? const Color(0xFF3D8BFF)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Product Variants',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _hasVariants
                              ? const Color(0xFF3D8BFF)
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _hasVariants,
                    onChanged: (v) => setState(() {
                      _hasVariants = v;
                      if (v) {
                        _variants = {'Size': [], 'Color': []};
                      } else {
                        _variants = {};
                      }
                    }),
                  ),
                ],
              ),
              if (_hasVariants) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildQuickTemplates(),
                const SizedBox(height: 16),
                _buildColorsSection(),
                const SizedBox(height: 16),
                _buildSizesSection(),
                const SizedBox(height: 16),
                _buildCustomVariantSection(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTemplateChip('Clothing Size', Icons.checkroom, () {
              setState(() {
                _variants['Size'] = clothingSizes['Clothing']!;
              });
            }),
            _buildTemplateChip('T-Shirt Size', Icons.checkroom, () {
              setState(() {
                _variants['Size'] = apparelSizes['Shirt']!;
              });
            }),
            _buildTemplateChip('Jeans', Icons.straighten, () {
              setState(() {
                _variants['Size'] = apparelSizes['Jeans']!;
              });
            }),
            _buildTemplateChip('Shoes (US Men)', Icons.directions_walk, () {
              setState(() {
                _variants['Size'] = shoeSizes['US Men']!;
              });
            }),
            _buildTemplateChip('Shoes (US Women)', Icons.directions_walk, () {
              setState(() {
                _variants['Size'] = shoeSizes['US Women']!;
              });
            }),
            _buildTemplateChip('Shoes (EU)', Icons.directions_walk, () {
              setState(() {
                _variants['Size'] = shoeSizes['EU']!;
              });
            }),
            _buildTemplateChip('Kids Size', Icons.child_care, () {
              setState(() {
                _variants['Size'] = clothingSizes['Kids']!;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFE8F0FE),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1A73E8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorsSection() {
    final colorOptions = _variants['Color'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Colors',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showColorPicker(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Color'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A73E8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddColorDialog(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Custom'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (colorOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorOptions.map((colorHex) {
              final colorValue = int.tryParse(colorHex.replaceAll('#', ''), radix: 16) ?? 0xFF000000;
              final displayColor = Color(0xFF000000 | colorValue);
              final colorName = colorNames[colorHex] ?? 'Custom';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: displayColor.computeLuminance() > 0.5 ? Colors.black12 : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      colorName,
                      style: TextStyle(
                        color: displayColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          colorOptions.remove(colorHex);
                          _variants['Color'] = colorOptions;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: displayColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'No colors added. Tap "Add Color" to select from palette.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildSizesSection() {
    final sizeOptions = _variants['Size'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sizes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSizePicker(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Size'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
              ),
            ),
          ],
        ),
        if (sizeOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizeOptions.map((size) {
              return Chip(
                label: Text(
                  size,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onDeleted: () {
                  setState(() {
                    sizeOptions.remove(size);
                    _variants['Size'] = sizeOptions;
                  });
                },
                backgroundColor: const Color(0xFFE8F0FE),
                deleteIconColor: const Color(0xFF1A73E8),
              );
            }).toList(),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'No sizes added. Use quick templates above or add custom sizes.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Other Variants',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddVariantDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Custom'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
              ),
            ),
          ],
        ),
        if (_variants.entries.any((e) => e.key != 'Size' && e.key != 'Color' && e.value.isNotEmpty)) ...[
          const SizedBox(height: 8),
          ..._variants.entries.where((e) => e.key != 'Size' && e.key != 'Color' && e.value.isNotEmpty).map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: entry.value.map((opt) => Chip(
                            label: Text(opt, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            onDeleted: () {
                              setState(() {
                                entry.value.remove(opt);
                              });
                            },
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => setState(() => _variants.remove(entry.key)),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: predefinedColors.length,
                  itemBuilder: (context, index) {
                    final color = predefinedColors[index];
                    final hexColor = color.value.toRadixString(16).substring(2).toUpperCase();
                    final name = colorNames[hexColor] ?? 'Color';

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (!_variants['Color']!.contains(hexColor)) {
                            _variants['Color']!.add(hexColor);
                          }
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSizePicker() {
    final sizes = <String>{
      ...clothingSizes['Clothing']!,
      ...clothingSizes['Kids']!,
      ...shoeSizes['US Men']!,
      ...shoeSizes['US Women']!,
      ...shoeSizes['UK']!,
      ...shoeSizes['EU']!,
      ...apparelSizes['Shirt']!,
      ...apparelSizes['Jeans']!,
    }.toList()..sort();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: const Text('Add Custom Size'),
                leading: const Icon(Icons.add),
                onTap: () {
                  Navigator.pop(context);
                  _showAddVariantOptionDialog('Size');
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Quick Select',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sizes.map((size) {
                  final isSelected = _variants['Size']!.contains(size);
                  return FilterChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _variants['Size']!.add(size);
                        } else {
                          _variants['Size']!.remove(size);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFE8F0FE),
                    checkmarkColor: const Color(0xFF1A73E8),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddColorDialog() {
    final controller = TextEditingController();
    Color selectedColor = Colors.black;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Color Name',
                  hintText: 'e.g., Navy Blue',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: predefinedColors.take(12).map((color) {
                  return InkWell(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: selectedColor == color
                            ? Border.all(color: const Color(0xFF1A73E8), width: 3)
                            : Border.all(color: Colors.grey[300]!),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final colorName = controller.text.trim();
                final colorHex = selectedColor.value.toRadixString(16).substring(2).toUpperCase();
                if (colorName.isNotEmpty) {
                  setState(() {
                    if (!_variants['Color']!.contains(colorHex)) {
                      _variants['Color']!.add(colorHex);
                    }
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVariantDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Variant Category'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'E.g., Size, Color'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = nameCtrl.text.trim();
              if (val.isNotEmpty && !_variants.containsKey(val)) {
                setState(() => _variants[val] = []);
                Navigator.pop(ctx);
                _showAddVariantOptionDialog(val);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddVariantOptionDialog(String categoryKey) {
    final optCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Option to $categoryKey'),
        content: TextField(
          controller: optCtrl,
          decoration: const InputDecoration(hintText: 'E.g., Large, Red'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = optCtrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  if (!_variants[categoryKey]!.contains(val)) {
                    _variants[categoryKey]!.add(val);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (option == null) return;

    if (option == 'remove') {
      setState(() => _imagePath = null);
      return;
    }

    final picker = ImagePicker();
    final source =
        option == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(appDir.path, fileName);
      await File(pickedFile.path).copy(savedPath);
      setState(() => _imagePath = savedPath);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.product != null;
      final stockText = _stockController.text.trim();
      final minStockText = _minStockController.text.trim();
      final stock = _isService
          ? 0
          : int.tryParse(stockText.isEmpty ? '0' : stockText) ?? 0;
      final minStock = _isService
          ? 0
          : int.tryParse(minStockText.isEmpty ? '0' : minStockText) ?? 0;

      if (isEdit) {
        // Update existing product
        String? variantOptionsJson;
        if (_hasVariants && _variants.isNotEmpty) {
          variantOptionsJson = jsonEncode(_variants);
        }

        final updatedProduct = widget.product!.copyWith(
          name: _nameController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty
              ? null
              : _barcodeController.text.trim(),
          price: double.parse(_priceController.text),
          costPrice: _costPriceController.text.isEmpty
              ? 0.0
              : double.parse(_costPriceController.text),
          stock: stock,
          minStock: minStock,
          unit: _selectedUnit,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          imagePath: _imagePath,
          hasVariants: _hasVariants,
          variantOptions: variantOptionsJson,
          expiryDate: _expiryAlertEnabled ? _expiryDate : null,
          expiryAlertEnabled: _expiryAlertEnabled,
          expiryAlertDays: _expiryAlertDays,
          updatedAt: DateTime.now(),
        );

        final success = await ref
            .read(productActionsProvider.notifier)
            .updateProduct(updatedProduct);

        if (mounted) {
          if (success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to update product'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } else {
        // Add new product
        String? variantOptionsJson;
        if (_hasVariants && _variants.isNotEmpty) {
          variantOptionsJson = jsonEncode(_variants);
        }

        final id = await ref.read(productActionsProvider.notifier).addProduct(
              name: _nameController.text.trim(),
              barcode: _barcodeController.text.trim().isEmpty
                  ? null
                  : _barcodeController.text.trim(),
              price: double.parse(_priceController.text),
              costPrice: _costPriceController.text.isEmpty
                  ? 0.0
                  : double.parse(_costPriceController.text),
              stock: stock,
              minStock: minStock,
              unit: _selectedUnit,
              category: _categoryController.text.trim().isEmpty
                  ? null
                  : _categoryController.text.trim(),
              imagePath: _imagePath,
              expiryDate: _expiryAlertEnabled ? _expiryDate : null,
              expiryAlertEnabled: _expiryAlertEnabled,
              expiryAlertDays: _expiryAlertDays,
            );

        if (mounted) {
          if (id > 0) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product added successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to add product'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
