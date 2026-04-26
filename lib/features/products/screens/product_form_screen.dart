import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            Text(
              'Expiry Date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Switch(
              value: _expiryAlertEnabled,
              onChanged: (value) => setState(() => _expiryAlertEnabled = value),
            ),
          ],
        ),
        if (_expiryAlertEnabled) ...[
          const SizedBox(height: 10),
          TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: _expiryDate == null
                  ? 'Select expiry date'
                  : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onTap: _pickExpiryDate,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _expiryAlertDays,
            decoration: const InputDecoration(
              labelText: 'Alert before',
            ),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _expiryAlertDays = value);
              }
            },
          ),
        ],
      ],
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

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
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
