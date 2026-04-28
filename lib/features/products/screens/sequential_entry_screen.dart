import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/validators.dart';
import '../../settings/models/item_settings.dart';
import '../../settings/providers/item_settings_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sequential_entry_provider.dart';
import '../models/variant_model.dart';

class SequentialEntryScreen extends ConsumerStatefulWidget {
  const SequentialEntryScreen({super.key});

  @override
  ConsumerState<SequentialEntryScreen> createState() => _SequentialEntryScreenState();
}

class _SequentialEntryScreenState extends ConsumerState<SequentialEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _searchSizeController = TextEditingController();
  final _searchColorController = TextEditingController();

  bool _isLoading = false;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _searchSizeController.dispose();
    _searchColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sequentialEntryProvider);
    final notifier = ref.watch(sequentialEntryProvider.notifier);
    final settingsAsync = ref.watch(itemSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? ItemSettings.defaults();
    final isLandscape = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item - Quick Entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        actions: [
          if (settings.sequentialEntryEnabled)
            TextButton.icon(
              onPressed: () => _toggleMode(context),
              icon: const Icon(Icons.view_agenda),
              label: const Text('Form'),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isLandscape) {
            return _buildLandscapeLayout(context, state, notifier, settings);
          }
          return _buildPortraitLayout(context, state, notifier, settings);
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      children: [
        _buildProgressIndicator(state),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentStep(context, state, notifier, settings),
          ),
        ),
        _buildNavigationButtons(context, state, notifier, settings),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              _buildProgressIndicator(state),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: _buildCurrentStep(context, state, notifier, settings),
                ),
              ),
              _buildNavigationButtons(context, state, notifier, settings),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildLivePreview(context, state, settings),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(SequentialEntryState state) {
    final totalSteps = state.calculatedTotalSteps;
    final progress = (state.currentStep + 1) / totalSteps;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.stepTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Step ${state.currentStep + 1} of $totalSteps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    final step = state.currentStep;

    switch (step) {
      case 0:
        return _buildImageStep(context, state, notifier, settings);
      case 1:
        return _buildNameStep(context, state, notifier, settings);
      case 2:
        return _buildPriceStep(context, state, notifier, settings);
      case 3:
        return _buildQuantityStep(context, state, notifier, settings);
      case 4:
        return _buildVariantsStep(context, state, notifier, settings);
      case 5:
        return _buildSizesStep(context, state, notifier, settings);
      case 6:
        return _buildColorsStep(context, state, notifier, settings);
      case 7:
        return _buildCombinationsStep(context, state, notifier, settings);
      case 8:
        return _buildReviewStep(context, state, notifier, settings);
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  Widget _buildImageStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Take or upload a photo of your product',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: state.imagePath != null
              ? _buildImagePreview(state.imagePath!)
              : _buildImagePickerButton(context, notifier),
        ),
        if (state.imagePath != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => notifier.setImage(''),
              icon: const Icon(Icons.refresh),
              label: const Text('Change Image'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview(String imagePath) {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: File(imagePath).existsSync()
            ? Image.file(File(imagePath), fit: BoxFit.cover)
            : const Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildImagePickerButton(BuildContext context, SequentialEntryNotifier notifier) {
    return InkWell(
      onTap: () => _pickImage(context, notifier),
      child: Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add image',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Name *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter product name',
            prefixIcon: Icon(Icons.inventory_2),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) => Validators.requiredField(v, fieldName: 'Product name'),
          onChanged: notifier.setProductName,
          onFieldSubmitted: (_) => ref.read(sequentialEntryProvider.notifier).nextStep(),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(context, notifier),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, SequentialEntryNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTemplateChip('T-Shirt', () {
              _nameController.text = 'T-Shirt';
              notifier.setProductName('T-Shirt');
            }),
            _buildTemplateChip('Jeans', () {
              _nameController.text = 'Jeans';
              notifier.setProductName('Jeans');
            }),
            _buildTemplateChip('Shirt', () {
              _nameController.text = 'Shirt';
              notifier.setProductName('Shirt');
            }),
            _buildTemplateChip('Jacket', () {
              _nameController.text = 'Jacket';
              notifier.setProductName('Jacket');
            }),
            _buildTemplateChip('Shoes', () {
              _nameController.text = 'Shoes';
              notifier.setProductName('Shoes');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildPriceStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selling Price *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            hintText: 'Enter selling price',
            prefixIcon: Icon(Icons.currency_rupee),
            prefixText: 'Rs. ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => Validators.positiveNumber(v, fieldName: 'Selling price'),
          onChanged: (v) {
            final price = double.tryParse(v);
            if (price != null) notifier.setSellingPrice(price);
          },
          onFieldSubmitted: (_) => ref.read(sequentialEntryProvider.notifier).nextStep(),
        ),
        const SizedBox(height: 16),
        _buildAdvancedToggle(),
        if (_showAdvanced) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _costPriceController,
            decoration: const InputDecoration(
              labelText: 'Cost Price (Optional)',
              hintText: 'Purchase price',
              prefixIcon: Icon(Icons.shopping_cart),
              prefixText: 'Rs. ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final price = double.tryParse(v);
              if (price != null) notifier.setCostPrice(price);
            },
          ),
        ],
        const SizedBox(height: 16),
        _buildSmartPrices(context),
      ],
    );
  }

  Widget _buildAdvancedToggle() {
    return InkWell(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Row(
        children: [
          Icon(
            _showAdvanced ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _showAdvanced ? 'Hide Advanced' : 'Show Advanced Options',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPrices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Price',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPriceChip('500', () => _setPrice(500)),
            _buildPriceChip('1000', () => _setPrice(1000)),
            _buildPriceChip('1500', () => _setPrice(1500)),
            _buildPriceChip('2000', () => _setPrice(2000)),
            _buildPriceChip('2500', () => _setPrice(2500)),
            _buildPriceChip('5000', () => _setPrice(5000)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text('Rs. $label'),
      onPressed: onTap,
    );
  }

  void _setPrice(double price) {
    _priceController.text = price.toString();
    ref.read(sequentialEntryProvider.notifier).setSellingPrice(price);
  }

  Widget _buildQuantityStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Quantity',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _stockController,
          decoration: const InputDecoration(
            hintText: 'Enter quantity',
            prefixIcon: Icon(Icons.inventory),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final qty = int.tryParse(v) ?? 0;
            notifier.setQuantity(qty);
          },
          onFieldSubmitted: (_) => ref.read(sequentialEntryProvider.notifier).nextStep(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuantityChip('0', () => _setQuantity(0)),
            _buildQuantityChip('10', () => _setQuantity(10)),
            _buildQuantityChip('50', () => _setQuantity(50)),
            _buildQuantityChip('100', () => _setQuantity(100)),
            _buildQuantityChip('500', () => _setQuantity(500)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _setQuantity(int qty) {
    _stockController.text = qty.toString();
    ref.read(sequentialEntryProvider.notifier).setQuantity(qty);
  }

  Widget _buildVariantsStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: state.enableVariants
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.enableVariants
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.style,
                    color: state.enableVariants
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product has Variants',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Size, Color, etc.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: state.enableVariants,
                onChanged: notifier.setEnableVariants,
              ),
            ],
          ),
        ),
        if (!state.enableVariants) ...[
          const SizedBox(height: 16),
          const Text('Skip variants and save directly'),
        ],
      ],
    );
  }

  Widget _buildSizesStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sizes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: () => _showAddSizeDialog(context, notifier),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSizeTemplates(context, notifier),
        const SizedBox(height: 16),
        if (state.sizes.isNotEmpty) ...[
          const Text('Selected Sizes:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.sizes.map((size) => Chip(
              label: Text(size),
              onDeleted: () => notifier.removeSize(size),
            )).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No sizes added. Use templates or add custom.'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSizeTemplates(BuildContext context, SequentialEntryNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildSizeTemplateChip('Clothing', clothingSizePresets, notifier),
            _buildSizeTemplateChip('Shirt', shirtSizePresets, notifier),
            _buildSizeTemplateChip('Jeans', jeansSizePresets, notifier),
            _buildSizeTemplateChip('US Men', shoeSizePresetsUSMen, notifier),
            _buildSizeTemplateChip('US Women', shoeSizePresetsUSWomen, notifier),
            _buildSizeTemplateChip('EU', shoeSizePresetsEU, notifier),
            _buildSizeTemplateChip('Kids', kidsSizePresets, notifier),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeTemplateChip(String label, List<String> sizes, SequentialEntryNotifier notifier) {
    return ActionChip(
      avatar: const Icon(Icons.checkroom, size: 16),
      label: Text(label),
      onPressed: () {
        for (final size in sizes) {
          notifier.addSize(size);
        }
      },
    );
  }

  Widget _buildColorsStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Colors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: () => _showAddColorDialog(context, notifier),
              icon: const Icon(Icons.add),
              label: const Text('Custom'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Select Colors:'),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: predefinedColors.length,
          itemBuilder: (context, index) {
            final color = predefinedColors[index];
            final isSelected = state.colors.any((c) => c.hex == color.hex);
            return InkWell(
              onTap: () {
                if (isSelected) {
                  notifier.removeColor(color);
                } else {
                  notifier.addColor(color);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: color.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.colorValue > 0xFF888888 ? Colors.white : Colors.black,
                        size: 20,
                      )
                    : null,
              ),
            );
          },
        ),
        if (state.colors.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Selected Colors:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.colors.map((color) => Chip(
              avatar: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!),
                ),
              ),
              label: Text(color.name),
              onDeleted: () => notifier.removeColor(color),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCombinationsStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    if (state.combinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No combinations to display'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => notifier.previousStep(),
              child: const Text('Go back to add sizes/colors'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Combinations (${state.combinations.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: state.combinations.length,
            itemBuilder: (context, index) {
              final combo = state.combinations[index];
              final key = '${combo.size}-${ combo.colorHex}';
              final stock = state.variantStock[key] ?? 0;

              return Card(
                child: ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.tryParse('FF${combo.colorHex}', radix: 16) ?? 0xFF000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                  ),
                  title: Text('${combo.size} - ${combo.colorName ?? combo.colorHex}'),
                  subtitle: Text('Stock: $stock'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Stock',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final qty = int.tryParse(v) ?? 0;
                        notifier.setVariantStock(key, qty);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Product',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryCard('Name', state.productName),
        _buildSummaryCard('Price', 'Rs. ${state.sellingPrice?.toString() ?? "0"}'),
        _buildSummaryCard('Quantity', state.quantity.toString()),
        if (state.enableVariants) ...[
          _buildSummaryCard('Sizes', state.sizes.join(', ')),
          _buildSummaryCard('Colors', state.colors.map((c) => c.name).join(', ')),
          _buildSummaryCard('Combinations', state.combinations.length.toString()),
        ],
        const SizedBox(height: 16),
        Text(
          'Auto-generated:',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        if (settings.autoBarcodeEnabled)
          _buildSummaryCard('Barcode', state.barcode ?? 'Auto-generated'),
        if (settings.autoSkuEnabled)
          _buildSummaryCard('SKU', state.sku ?? 'Auto-generated'),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLivePreview(BuildContext context, SequentialEntryState state, ItemSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Live Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (state.imagePath != null)
                  _buildImagePreview(state.imagePath!),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.productName.isEmpty ? 'Product Name' : state.productName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${state.sellingPrice?.toString() ?? "0"}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.enableVariants && state.sizes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Sizes: ${state.sizes.join(", ")}'),
                        ],
                        if (state.enableVariants && state.colors.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Colors: ${state.colors.map((c) => c.name).join(", ")}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, SequentialEntryState state, SequentialEntryNotifier notifier, ItemSettings settings) {
    final isLastStep = state.currentStep >= state.calculatedTotalSteps - 1;
    final canProceed = _canProceed(state);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: notifier.previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: canProceed
                    ? () {
                        if (isLastStep) {
                          _saveProduct(context, state, settings);
                        } else {
                          notifier.nextStep();
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE21B22),
                ),
                child: Text(isLastStep ? 'Save Product' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed(SequentialEntryState state) {
    switch (state.currentStep) {
      case 0:
        return true;
      case 1:
        return state.productName.isNotEmpty;
      case 2:
        return (state.sellingPrice ?? 0) > 0;
      case 3:
        return true;
      case 4:
        return true;
      case 5:
        return true;
      case 6:
        return true;
      case 7:
        return true;
      case 8:
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickImage(BuildContext context, SequentialEntryNotifier notifier) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
          ],
        ),
      ),
    );

    if (option == null) return;

    final picker = ImagePicker();
    final source = option == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(appDir.path, fileName);
      await File(pickedFile.path).copy(savedPath);
      notifier.setImage(savedPath);
    }
  }

  Future<void> _showAddSizeDialog(BuildContext context, SequentialEntryNotifier notifier) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Size'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., S, M, L or 28, 30',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      notifier.addSize(result);
    }
  }

  Future<void> _showAddColorDialog(BuildContext context, SequentialEntryNotifier notifier) async {
    final controller = TextEditingController();
    Color selectedColor = Colors.black;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final colorName = controller.text.trim();
                if (colorName.isNotEmpty) {
                  final hex = selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase();
                  Navigator.pop(context, '$hex|$colorName');
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final parts = result.split('|');
      if (parts.length == 2) {
        notifier.addColor(ColorOption(hex: parts[0], name: parts[1]));
      }
    }
  }

  Future<void> _saveProduct(BuildContext context, SequentialEntryState state, ItemSettings settings) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final id = await ref.read(productActionsProvider.notifier).addProduct(
        name: state.productName,
        barcode: settings.autoBarcodeEnabled
            ? (state.barcode ?? VariantHelper.generateBarcode(state.productName, '', ''))
            : null,
        price: state.sellingPrice ?? 0,
        costPrice: state.costPrice ?? 0,
        stock: state.quantity,
        minStock: 0,
        unit: state.selectedUnit,
        category: state.category.isEmpty ? null : state.category,
        imagePath: state.imagePath,
      );

      if (mounted) {
        if (id > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to add product'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to exit? Your data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(sequentialEntryProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _toggleMode(BuildContext context) {
    Navigator.pop(context);
  }
}