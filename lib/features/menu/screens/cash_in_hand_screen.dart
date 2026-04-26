import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashInHandScreen extends ConsumerStatefulWidget {
  const CashInHandScreen({super.key});

  @override
  ConsumerState<CashInHandScreen> createState() => _CashInHandScreenState();
}

class _CashInHandScreenState extends ConsumerState<CashInHandScreen> {
  double _cashBalance = 0.0;
  final List<CashTransaction> _transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Cash In-Hand'),
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          Expanded(
            child: _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: txn.isIncome
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              txn.isIncome ? Icons.add : Icons.remove,
                              color: txn.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(txn.description),
                          subtitle: Text(txn.date.toString().split(' ')[0]),
                          trailing: Text(
                            'Rs. ${txn.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: txn.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_cash',
            onPressed: () => _addTransaction(true),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'remove_cash',
            onPressed: () => _addTransaction(false),
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Current Cash Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. ${_cashBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _cashBalance >= 0 ? Colors.green : Colors.red,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 120,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No cash transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Add cash in or cash out transactions'),
        ],
      ),
    );
  }

  void _addTransaction(bool isIncome) {
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncome ? 'Cash In' : 'Cash Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
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
              final amount = double.tryParse(amountController.text) ?? 0;
              setState(() {
                _transactions.insert(
                  0,
                  CashTransaction(
                    description: descController.text,
                    amount: amount,
                    isIncome: isIncome,
                    date: DateTime.now(),
                  ),
                );
                _cashBalance += isIncome ? amount : -amount;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class CashTransaction {
  final String description;
  final double amount;
  final bool isIncome;
  final DateTime date;

  CashTransaction({
    required this.description,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}
