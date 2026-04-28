import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/providers/products_provider.dart';
import '../../products/models/product_model.dart';
import '../providers/pos_provider.dart';
import '../models/pos_models.dart';
import '../../customers/providers/customers_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class ModernPosScreen extends ConsumerStatefulWidget {
  const ModernPosScreen({super.key});

  @override
  ConsumerState<ModernPosScreen> createState() => _ModernPosScreenState();
}

class _ModernPosScreenState extends ConsumerState<ModernPosScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _taxEnabled = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    // Auto-focus search for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // LEFT: Product Grid (70%)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildTopBar(),
                _buildSearchBar(),
                _buildCategoryTabs(),
                Expanded(child: _buildProductGrid(productsAsync)),
              ],
            ),
          ),
          // RIGHT: Cart Panel (30%)
          Container(
            width: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: _buildCartPanel(cart),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          const Text(
            'Point of Sale',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          const Spacer(),
          _buildTopBarButton(Icons.history_outlined, 'History', () => context.push('/transactions')),
          const SizedBox(width: 8),
          _buildTopBarButton(Icons.person_add_alt_outlined, 'Customer', _showCustomerPicker),
          const SizedBox(width: 8),
          _buildTopBarButton(Icons.settings_outlined, 'Settings', () {}),
        ],
      ),
    );
  }

  Widget _buildTopBarButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF495057)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF495057))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search products (F2) or scan barcode...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : const Icon(Icons.qr_code_scanner, size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Consumer(
      builder: (context, ref, _) {
        final categoriesAsync = ref.watch(productCategoriesProvider);
        return categoriesAsync.when(
          data: (categories) => Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryTab('All', _selectedCategory == null),
                ...categories.map((c) => _buildCategoryTab(c, _selectedCategory == c)),
              ],
            ),
          ),
          loading: () => const SizedBox(height: 50),
          error: (_, __) => const SizedBox(height: 50),
        );
      },
    );
  }

  Widget _buildCategoryTab(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? const Color(0xFF1D9E75) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = label == 'All' ? null : label),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF495057),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(AsyncValue<List<ProductModel>> productsAsync) {
    return productsAsync.when(
      data: (products) {
        final filtered = products.where((p) {
          final matchQuery = _searchQuery.isEmpty ||
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.barcode?.contains(_searchQuery) ?? false);
          final matchCategory = _selectedCategory == null || p.category == _selectedCategory;
          return matchQuery && matchCategory && p.isActive;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No products found', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildProductCard(filtered[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final lowStock = product.stock <= product.minStock;
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: product.imagePath != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.file(
                                  File(product.imagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
                                ),
                              )
                            : Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]),
                      ),
                      if (lowStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Low', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D9E75)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: lowStock ? Colors.red[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: lowStock ? Colors.red : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(ProductModel product) {
    ref.read(posCartProvider.notifier).addItem(product);
    _animController.forward().then((_) => _animController.reverse());
    HapticFeedback.lightImpact();
  }

  Widget _buildCartPanel(PosCartState cart) {
    return Column(
      children: [
        _buildCartHeader(cart),
        if (cart.selectedCustomer != null) _buildCustomerCard(cart),
        _buildTaxToggle(),
        Expanded(child: _buildCartItems(cart)),
        _buildCartSummary(cart),
      ],
    );
  }

  Widget _buildCartHeader(PosCartState cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${cart.totalItems} items', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmClearCart,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(PosCartState cart) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cart.selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (cart.selectedCustomer!.phone != null)
                  Text(cart.selectedCustomer!.phone!, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(posCartProvider.notifier).setCustomer(null),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _taxEnabled ? const Color(0xFFE8F5F1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _taxEnabled ? const Color(0xFF1D9E75) : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: 20, color: _taxEnabled ? const Color(0xFF1D9E75) : Colors.grey[600]),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tax (VAT 13%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(_taxEnabled ? 'Enabled' : 'Disabled', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          Switch(
            value: _taxEnabled,
            onChanged: (val) => setState(() => _taxEnabled = val),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF1D9E75)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(PosCartState cart) {
    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Cart is empty', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Add products to start', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildCartItemCard(cart.items[index], index),
    );
  }

  Widget _buildCartItemCard(PosCartItem item, int index) {
    final priceController = TextEditingController(text: item.product.price.toStringAsFixed(2));
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.selectedVariant != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.selectedVariant!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref.read(posCartProvider.notifier).removeItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    _buildQtyButton(Icons.remove, () {
                      if (item.quantity > 1) {
                        ref.read(posCartProvider.notifier).updateQuantity(index, item.quantity - 1);
                      }
                    }),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    _buildQtyButton(Icons.add, () {
                      ref.read(posCartProvider.notifier).updateQuantity(index, item.quantity + 1);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Editable price
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      prefixText: 'Rs ',
                      prefixStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onChanged: (val) {
                      final newPrice = double.tryParse(val);
                      if (newPrice != null && newPrice > 0) {
                        ref.read(posCartProvider.notifier).updatePrice(index, newPrice);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Total
              Text(
                CurrencyFormatter.format(item.totalPrice),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D9E75)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF495057)),
      ),
    );
  }

  Widget _buildCartSummary(PosCartState cart) {
    final taxAmount = _taxEnabled ? cart.taxAmount : 0.0;
    final total = cart.subtotal - cart.calculatedDiscount + taxAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', CurrencyFormatter.format(cart.subtotal)),
          if (cart.calculatedDiscount > 0)
            _buildSummaryRow('Discount', '- ${CurrencyFormatter.format(cart.calculatedDiscount)}', color: Colors.red),
          if (_taxEnabled)
            _buildSummaryRow('Tax (13%)', CurrencyFormatter.format(taxAmount), color: Colors.orange),
          const Divider(height: 24, thickness: 1.5),
          _buildSummaryRow('Total', CurrencyFormatter.format(total), isBold: true, fontSize: 20),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: cart.items.isEmpty ? null : () => _checkout(cart, total),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 22),
                  SizedBox(width: 12),
                  Text('Complete Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (isBold ? const Color(0xFF1D9E75) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _checkout(PosCartState cart, double total) {
    // Quick checkout implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: ${CurrencyFormatter.format(total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Select payment method:'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(posCartProvider.notifier).checkout();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment completed successfully!')),
                );
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final customersAsync = ref.watch(customersStreamProvider);
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: const Row(
                    children: [
                      Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: customersAsync.when(
                    data: (customers) => ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1D9E75),
                            child: Text(customer.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        title: const Text('Clear Cart?'),
        content: const Text('This will remove all items from the cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(posCartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
