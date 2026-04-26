import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/validators.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String type;
  final TransactionModel? transaction;

  const TransactionFormScreen({
    super.key,
    required this.type,
    this.transaction,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  double _vatRate = 0.13; // 13% VAT
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadTransaction(widget.transaction!);
    }
  }

  void _loadTransaction(TransactionModel transaction) {
    _customerNameController.text = transaction.customerName ?? '';
    _amountController.text = transaction.amount.toString();
    _notesController.text = transaction.notes ?? '';
    _selectedPaymentMethod = transaction.paymentMethod;
    _selectedDate = transaction.transactionDate;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;

    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(_getTitle()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.type == 'sale' || widget.type == 'purchase')
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Enter customer name',
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
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => Validators.positiveNumber(
                        value,
                        fieldName: 'Amount',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: ['Cash', 'eSewa', 'Khalti', 'fonepay', 'Bank Transfer'].map((method) {
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _selectDate(context),
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
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_amountController.text.isNotEmpty)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        'Amount',
                        double.tryParse(_amountController.text) ?? 0,
                      ),
                      if (_vatRate > 0) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'VAT (13%)',
                          (double.tryParse(_amountController.text) ?? 0) * _vatRate,
                        ),
                      ],
                      const Divider(height: 24),
                      _buildSummaryRow(
                        'Total',
                        _calculateTotal(),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE21B22),
                minimumSize: const Size.fromHeight(56),
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
                  : Text(isEdit ? 'Update Transaction' : 'Add Transaction'),
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    final isEdit = widget.transaction != null;
    switch (widget.type) {
      case 'sale':
        return isEdit ? 'Edit Sale' : 'New Sale';
      case 'purchase':
        return isEdit ? 'Edit Purchase' : 'New Purchase';
      case 'expense':
        return isEdit ? 'Edit Expense' : 'New Expense';
      case 'payment':
        return isEdit ? 'Edit Payment' : 'New Payment';
      case 'receipt':
        return isEdit ? 'Edit Receipt' : 'New Receipt';
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
        id: widget.transaction?.id ?? 0,
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
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );

      await ref.read(transactionActionsProvider.notifier).addTransaction(transaction);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
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
