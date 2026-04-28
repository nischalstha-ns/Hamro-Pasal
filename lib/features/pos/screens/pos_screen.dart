import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/providers/products_provider.dart';
import '../../products/models/product_model.dart';
import '../providers/pos_provider.dart';
import '../models/pos_models.dart';
import '../../customers/providers/customers_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dart:convert';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/checkout_dialog.dart';
import 'pos_receipt_screen.dart';
import '../../transactions/providers/transactions_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('POS System', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: const Text('Classic Form'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF1D9E75)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black87),
            onPressed: () => context.push('/transactions'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.black87),
            onPressed: () => _showCustomerPicker(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 900;
          
          if (isTablet) {
            return Row(
              children: [
                // Left side: Product selection
                Expanded(
                  flex: 3,
                  child: _buildProductSection(productsAsync, categoriesAsync),
                ),
                // Right side: Cart
                Container(
                  width: 380,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: _buildCartSection(cart),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(
                  child: _buildProductSection(productsAsync, categoriesAsync),
                ),
                _buildMobileCartSummary(cart),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildProductSection(AsyncValue<List<ProductModel>> productsAsync, AsyncValue<List<String>> categoriesAsync) {
    return Column(
      children: [
        // Search and Filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search products by name or barcode...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _startBarcodeScanner(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('All', _selectedCategory == null),
                      ...categories.map((c) => _buildCategoryChip(c, _selectedCategory == c)),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox(height: 40),
              ),
            ],
          ),
        ),
        // Product Grid
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final filtered = products.where((p) {
                final matchQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 (p.barcode != null && p.barcode!.contains(_searchQuery));
                final matchCategory = _selectedCategory == null || p.category == _selectedCategory;
                return matchQuery && matchCategory;
              }).toList();
              
              if (filtered.isEmpty) {
                return const Center(child: Text('No products found'));
              }
              
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildProductCard(filtered[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedCategory = label == 'All' ? null : label;
          });
        },
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleProductTap(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: product.imagePath != null
                    ? _buildProductImage(product.imagePath!)
                    : const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${product.stock} ${product.unit}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    const icon = Icon(Icons.image_not_supported, color: Colors.grey);
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => icon);
    } else {
      return Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => icon);
    }
  }

  void _handleProductTap(ProductModel product) {
    if (product.hasVariants && product.variantOptions != null) {
      _showVariantSelector(product);
    } else {
      ref.read(posCartProvider.notifier).addItem(product);
    }
  }

  void _showVariantSelector(ProductModel product) {
    final Map<String, dynamic> options = jsonDecode(product.variantOptions!);
    final Map<String, String> selections = {};
    
    // Initialize selections with the first option for each category
    options.forEach((key, value) {
      if ((value as List).isNotEmpty) {
        selections[key] = value[0].toString();
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select Options for ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (entry.value as List).map((opt) {
                      final isSelected = selections[entry.key] == opt.toString();
                      return ChoiceChip(
                        label: Text(opt.toString()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setDialogState(() => selections[entry.key] = opt.toString());
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final variantStr = selections.entries.map((e) => '${e.key}: ${e.value}').join(', ');
                ref.read(posCartProvider.notifier).addItem(product, variant: variantStr);
                Navigator.pop(context);
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection(PosCartState cart) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                onPressed: () => _confirmClearCart(),
              ),
            ],
          ),
        ),
        if (cart.selectedCustomer != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cart.selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (cart.selectedCustomer!.phone != null)
                        Text(cart.selectedCustomer!.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => ref.read(posCartProvider.notifier).setCustomer(null),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: cart.items.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) => _buildCartItem(cart.items[index], index),
                ),
        ),
        _buildCartSummary(cart),
      ],
    );
  }

  Widget _buildCartItem(PosCartItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.selectedVariant != null)
                  Text(item.selectedVariant!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(CurrencyFormatter.format(item.product.price), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyBtn(Icons.remove, () => ref.read(posCartProvider.notifier).updateQuantity(index, item.quantity - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _buildQtyBtn(Icons.add, () => ref.read(posCartProvider.notifier).updateQuantity(index, item.quantity + 1)),
            ],
          ),
          const SizedBox(width: 12),
          Text(CurrencyFormatter.format(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildCartSummary(PosCartState cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', CurrencyFormatter.format(cart.subtotal)),
          _buildSummaryRow('Discount', '- ${CurrencyFormatter.format(cart.calculatedDiscount)}'),
          _buildSummaryRow('Tax (VAT 13%)', CurrencyFormatter.format(cart.taxAmount)),
          const Divider(height: 24),
          _buildSummaryRow('Total', CurrencyFormatter.format(cart.total), isBold: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: cart.items.isEmpty ? null : () => _showCheckoutDialog(cart),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF1D9E75),
              ),
              child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFF1D9E75) : null)),
        ],
      ),
    );
  }

  Widget _buildMobileCartSummary(PosCartState cart) {
    return InkWell(
      onTap: () => _showMobileCart(context, cart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D9E75),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                if (cart.totalItems > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            const Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(CurrencyFormatter.format(cart.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showMobileCart(BuildContext context, PosCartState cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: _buildCartSection(cart),
      ),
    );
  }

  void _showCustomerPicker(BuildContext context) {
    // This would ideally be a separate widget/dialog to pick from customers
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final customersAsync = ref.watch(customersStreamProvider);
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: customersAsync.when(
                    data: (customers) => ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: Text(customer.phone ?? 'No phone'),
                          onTap: () {
                            ref.read(posCartProvider.notifier).setCustomer(customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from the cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(posCartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerView(
          onDetect: (barcode) {
            _handleBarcodeScan(barcode);
          },
        ),
      ),
    );
  }

  void _handleBarcodeScan(String barcode) {
    final products = ref.read(productsStreamProvider).value ?? [];
    try {
      final product = products.firstWhere((p) => p.barcode == barcode || p.sku == barcode);
      _handleProductTap(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added: ${product.name}'), duration: const Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product with barcode $barcode not found')),
      );
    }
  }

  void _showCheckoutDialog(PosCartState cart) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CheckoutDialog(cart: cart),
    );

    if (result != null && result['id'] != null) {
      final transactionId = result['id'] as int;
      final shouldPrint = result['print'] as bool;

      if (shouldPrint) {
        // Fetch full transaction data and show receipt
        final transaction = await ref.read(transactionByIdProvider(transactionId).future);
        if (transaction != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PosReceiptScreen(
                transaction: transaction,
                items: transaction.items,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction completed successfully!')));
        }
      }
    }
  }
}
