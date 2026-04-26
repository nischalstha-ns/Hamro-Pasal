import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanAccountsScreen extends ConsumerStatefulWidget {
  const LoanAccountsScreen({super.key});

  @override
  ConsumerState<LoanAccountsScreen> createState() => _LoanAccountsScreenState();
}

class _LoanAccountsScreenState extends ConsumerState<LoanAccountsScreen> {
  final List<LoanAccount> _loans = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Loan Accounts'),
      ),
      body: _loans.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final loan = _loans[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: loan.type == 'Given'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        loan.type == 'Given'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: loan.type == 'Given' ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      loan.partyName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${loan.type} • ${loan.interestRate}% interest\nDue: ${loan.dueDate.toString().split(' ')[0]}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${loan.remainingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: loan.type == 'Given' ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'of ${loan.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showLoanDetails(loan, index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLoan,
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
            Icons.volunteer_activism_outlined,
            size: 120,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No loan accounts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Track loans given or taken'),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 44,
            child: FilledButton.icon(
              onPressed: _addLoan,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Loan'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addLoan() {
    showDialog(
      context: context,
      builder: (context) => _LoanDialog(
        onSave: (loan) {
          setState(() => _loans.insert(0, loan));
        },
      ),
    );
  }

  void _showLoanDetails(LoanAccount loan, int index) {
    showDialog(
      context: context,
      builder: (context) => _LoanDialog(
        loan: loan,
        onSave: (updatedLoan) {
          setState(() => _loans[index] = updatedLoan);
        },
        onDelete: () {
          setState(() => _loans.removeAt(index));
        },
      ),
    );
  }
}

class LoanAccount {
  final String partyName;
  final double totalAmount;
  final double remainingAmount;
  final double interestRate;
  final DateTime dueDate;
  final String type;

  LoanAccount({
    required this.partyName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.dueDate,
    required this.type,
  });
}

class _LoanDialog extends StatefulWidget {
  final LoanAccount? loan;
  final Function(LoanAccount) onSave;
  final VoidCallback? onDelete;

  const _LoanDialog({
    this.loan,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<_LoanDialog> {
  late TextEditingController _partyNameController;
  late TextEditingController _totalAmountController;
  late TextEditingController _remainingAmountController;
  late TextEditingController _interestRateController;
  late DateTime _dueDate;
  late String _type;

  @override
  void initState() {
    super.initState();
    _partyNameController = TextEditingController(text: widget.loan?.partyName ?? '');
    _totalAmountController = TextEditingController(text: widget.loan?.totalAmount.toString() ?? '');
    _remainingAmountController = TextEditingController(text: widget.loan?.remainingAmount.toString() ?? '');
    _interestRateController = TextEditingController(text: widget.loan?.interestRate.toString() ?? '0');
    _dueDate = widget.loan?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _type = widget.loan?.type ?? 'Given';
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _totalAmountController.dispose();
    _remainingAmountController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.loan == null ? 'Add Loan' : 'Edit Loan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _partyNameController,
              decoration: const InputDecoration(
                labelText: 'Party Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Loan Type',
                border: OutlineInputBorder(),
              ),
              items: ['Given', 'Taken'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remainingAmountController,
              decoration: const InputDecoration(
                labelText: 'Remaining Amount',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _interestRateController,
              decoration: const InputDecoration(
                labelText: 'Interest Rate',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
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
            final loan = LoanAccount(
              partyName: _partyNameController.text,
              totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
              remainingAmount: double.tryParse(_remainingAmountController.text) ?? 0,
              interestRate: double.tryParse(_interestRateController.text) ?? 0,
              dueDate: _dueDate,
              type: _type,
            );
            widget.onSave(loan);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
