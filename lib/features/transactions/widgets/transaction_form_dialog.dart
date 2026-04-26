import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionFormDialog extends ConsumerStatefulWidget {
  final String type;

  const TransactionFormDialog({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<TransactionFormDialog> createState() =>
      _TransactionFormDialogState();
}

class _TransactionFormDialogState extends ConsumerState<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  double _vatRate = 0.13;
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: Text(_getTitle()),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              elevation: 0,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.type == 'sale' || widget.type == 'purchase')
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Enter customer name',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    if (widget.type == 'sale' || widget.type == 'purchase')
                      const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        prefixIcon: Icon(Icons.currency_rupee),
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.positiveNumber(
                        value,
                        fieldName: 'Amount',
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: ['Cash', 'eSewa', 'Khalti', 'fonepay', 'Bank Transfer']
                          .map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPaymentMethod = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.type == 'sale' || widget.type == 'purchase')
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include VAT (13%)'),
                        value: _vatRate > 0,
                        onChanged: (value) {
                          setState(() => _vatRate = value ? 0.13 : 0);
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.note_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                    if (_amountController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: const Color(0xFFF5F5F5),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                'Amount',
                                double.tryParse(_amountController.text) ?? 0,
                              ),
                              if (_vatRate > 0) ...[
                                const SizedBox(height: 8),
                                _buildSummaryRow(
                                  'VAT (13%)',
                                  (double.tryParse(_amountController.text) ?? 0) *
                                      _vatRate,
                                ),
                              ],
                              const Divider(height: 16),
                              _buildSummaryRow(
                                'Total',
                                _calculateTotal(),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE21B22),
                  minimumSize: const Size.fromHeight(48),
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
                    : const Text('Add Transaction'),
              ),
            ),
          ],
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
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  double _calculateTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final vat = amount * _vatRate;
    return amount + vat;
  }

  String _getTitle() {
    switch (widget.type) {
      case 'sale':
        return 'New Sale';
      case 'purchase':
        return 'New Purchase';
      case 'expense':
        return 'New Expense';
      case 'payment':
        return 'New Payment';
      case 'receipt':
        return 'New Receipt';
      default:
        return 'Transaction';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final vatAmount = amount * _vatRate;
      final totalAmount = amount + vatAmount;

      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final customerName = _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim();

      final transaction = TransactionModel(
        id: 0,
        invoiceNumber: invoiceNumber,
        type: widget.type,
        customerId: null,
        customerName: customerName,
        amount: amount,
        vatAmount: vatAmount,
        totalAmount: totalAmount,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        transactionDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      await ref
          .read(transactionActionsProvider.notifier)
          .addTransaction(transaction);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
