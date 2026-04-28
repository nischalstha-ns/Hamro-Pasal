import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pos_models.dart';
import '../providers/pos_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final PosCartState cart;

  const CheckoutDialog({super.key, required this.cart});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  final _receivedController = TextEditingController();
  final _notesController = TextEditingController();
  late String _selectedPaymentMethod;
  bool _shouldPrintReceipt = true;
  double _receivedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _receivedAmount = widget.cart.total;
    _receivedController.text = _receivedAmount.toStringAsFixed(2);
    _selectedPaymentMethod = widget.cart.paymentMethod;
    _notesController.text = widget.cart.notes;
  }

  @override
  void dispose() {
    _receivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _changeAmount => _receivedAmount - widget.cart.total;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Complete Checkout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Amounts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Total Amount', widget.cart.total, isBold: true, color: const Color(0xFF1D9E75)),
                      const SizedBox(height: 20),
                      const Text('Received Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _receivedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: 'Rs ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (val) {
                          setState(() {
                            _receivedAmount = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('Change to Return', _changeAmount >= 0 ? _changeAmount : 0, isBold: true, color: Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Side: Methods & Options
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ['Cash', 'eSewa', 'Khalti', 'fonepay', 'Bank Transfer']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPaymentMethod = val);
                            ref.read(posCartProvider.notifier).setPaymentMethod(val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Add Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Special request...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => ref.read(posCartProvider.notifier).setNotes(val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.print_outlined, size: 20),
                  const SizedBox(width: 12),
                  const Text('Print Receipt after finish'),
                  const Spacer(),
                  Switch(
                    value: _shouldPrintReceipt,
                    onChanged: (val) => setState(() => _shouldPrintReceipt = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _receivedAmount < widget.cart.total ? null : _handleFinish,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _shouldPrintReceipt ? 'FINISH & PRINT' : 'FINISH TRANSACTION',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, double value, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontSize: isBold ? 24 : 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _handleFinish() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactionId = await ref.read(posCartProvider.notifier).checkout();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        if (transactionId > 0) {
          Navigator.pop(context, {'print': _shouldPrintReceipt, 'id': transactionId});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save transaction')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
