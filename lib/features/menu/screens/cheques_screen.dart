import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChequesScreen extends ConsumerStatefulWidget {
  const ChequesScreen({super.key});

  @override
  ConsumerState<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends ConsumerState<ChequesScreen> {
  final List<Cheque> _cheques = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Cheques'),
      ),
      body: _cheques.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cheques.length,
              itemBuilder: (context, index) {
                final cheque = _cheques[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(cheque.status).withValues(alpha: 0.2),
                      child: Icon(
                        Icons.receipt_outlined,
                        color: _getStatusColor(cheque.status),
                      ),
                    ),
                    title: Text(
                      'Cheque #${cheque.chequeNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${cheque.partyName}\nDue: ${cheque.dueDate.toString().split(' ')[0]}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${cheque.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(cheque.status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cheque.status,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(cheque.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showChequeDetails(cheque, index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCheque,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 120,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No cheques added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Track your issued and received cheques'),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 44,
            child: FilledButton.icon(
              onPressed: _addCheque,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Cheque'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Cleared':
        return Colors.green;
      case 'Bounced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addCheque() {
    showDialog(
      context: context,
      builder: (context) => _ChequeDialog(
        onSave: (cheque) {
          setState(() => _cheques.insert(0, cheque));
        },
      ),
    );
  }

  void _showChequeDetails(Cheque cheque, int index) {
    showDialog(
      context: context,
      builder: (context) => _ChequeDialog(
        cheque: cheque,
        onSave: (updatedCheque) {
          setState(() => _cheques[index] = updatedCheque);
        },
        onDelete: () {
          setState(() => _cheques.removeAt(index));
        },
      ),
    );
  }
}

class Cheque {
  final String chequeNumber;
  final String partyName;
  final double amount;
  final DateTime dueDate;
  final String status;
  final String type;

  Cheque({
    required this.chequeNumber,
    required this.partyName,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.type,
  });
}

class _ChequeDialog extends StatefulWidget {
  final Cheque? cheque;
  final Function(Cheque) onSave;
  final VoidCallback? onDelete;

  const _ChequeDialog({
    this.cheque,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_ChequeDialog> createState() => _ChequeDialogState();
}

class _ChequeDialogState extends State<_ChequeDialog> {
  late TextEditingController _chequeNumberController;
  late TextEditingController _partyNameController;
  late TextEditingController _amountController;
  late DateTime _dueDate;
  late String _status;
  late String _type;

  @override
  void initState() {
    super.initState();
    _chequeNumberController = TextEditingController(text: widget.cheque?.chequeNumber ?? '');
    _partyNameController = TextEditingController(text: widget.cheque?.partyName ?? '');
    _amountController = TextEditingController(text: widget.cheque?.amount.toString() ?? '');
    _dueDate = widget.cheque?.dueDate ?? DateTime.now();
    _status = widget.cheque?.status ?? 'Pending';
    _type = widget.cheque?.type ?? 'Received';
  }

  @override
  void dispose() {
    _chequeNumberController.dispose();
    _partyNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cheque == null ? 'Add Cheque' : 'Edit Cheque'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _chequeNumberController,
              decoration: const InputDecoration(
                labelText: 'Cheque Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partyNameController,
              decoration: const InputDecoration(
                labelText: 'Party Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: ['Received', 'Issued'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['Pending', 'Cleared', 'Bounced'].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete!();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final cheque = Cheque(
              chequeNumber: _chequeNumberController.text,
              partyName: _partyNameController.text,
              amount: double.tryParse(_amountController.text) ?? 0,
              dueDate: _dueDate,
              status: _status,
              type: _type,
            );
            widget.onSave(cheque);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
