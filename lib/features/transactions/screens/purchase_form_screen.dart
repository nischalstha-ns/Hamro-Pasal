import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../../products/providers/products_provider.dart';
import '../../products/models/product_model.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierNameController = TextEditingController();
  final _supplierPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _paymentMethod = 'Cash';
  final DateTime _purchaseDate = DateTime.now();
  final List<_PurchaseItem> _items = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _vatAmount => _subtotal * 0.13;
  double get _total => _subtotal + _vatAmount;

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate() || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoiceNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch}';

      final transaction = TransactionModel(
        id: 0,
        invoiceNumber: invoiceNumber,
        type: 'purchase',
        customerName: _supplierNameController.text.isEmpty ? null : _supplierNameController.text,
        customerPhone: _supplierPhoneController.text.isEmpty ? null : _supplierPhoneController.text,
        amount: _subtotal,
        vatAmount: _vatAmount,
        totalAmount: _total,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        transactionDate: _purchaseDate,
        createdAt: DateTime.now(),
      );

      final txnItems = _items
          .map((item) => TransactionItemModel(
                id: 0,
                transactionId: 0,
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                unitPrice: item.price,
                totalPrice: item.total,
              ),)
          .toList();

      await ref.read(transactionActionsProvider.notifier).addTransactionWithItems(
            transaction: transaction,
            items: txnItems,
          );

      ref.invalidate(productsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return AdaptiveLayout(
      body: Scaffold(
        backgroundColor: const Color(0xFFDEE6F5),
        appBar: const AppHeader(),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supplier Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _supplierNameController,
                        decoration: const InputDecoration(
                          labelText: 'Supplier Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _supplierPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Items',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showAddItemDialog(productsAsync),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Item'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No items added'),
                          ),
                        )
                      else
                        ..._items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return ListTile(
                            title: Text(item.productName),
                            subtitle: Text('${item.quantity} × ${CurrencyFormatter.format(item.price)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => setState(() => _items.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', _subtotal),
                      const SizedBox(height: 8),
                      _buildSummaryRow('VAT (13%)', _vatAmount),
                      const Divider(height: 24),
                      _buildSummaryRow('Total', _total, isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: ['Cash', 'Bank Transfer', 'Cheque', 'Credit']
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                ),)
                            .toList(),
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _savePurchase,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Purchase'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog(AsyncValue<List<ProductModel>> productsAsync) {
    productsAsync.whenData((products) {
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products available')),
        );
        return;
      }

      ProductModel? selectedProduct = products.first;
      int quantity = 1;
      double price = products.first.costPrice;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProductModel>(
                  initialValue: selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    border: OutlineInputBorder(),
                  ),
                  items: products
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name),
                          ),)
                      .toList(),
                  onChanged: (p) => setDialogState(() {
                    selectedProduct = p;
                    price = p?.costPrice ?? 0;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => quantity = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: price.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => price = double.tryParse(v) ?? 0,
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
                  if (selectedProduct != null) {
                    setState(() {
                      _items.add(_PurchaseItem(
                        productId: selectedProduct!.id,
                        productName: selectedProduct!.name,
                        quantity: quantity,
                        price: price,
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PurchaseItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  _PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
