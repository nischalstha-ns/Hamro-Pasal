import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final List<BankAccount> _accounts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Bank Accounts'),
      ),
      body: _accounts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.account_balance,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      account.bankName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('A/C: ${account.accountNumber}'),
                    trailing: Text(
                      'Rs. ${account.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: account.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    onTap: () => _showAccountDetails(account, index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
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
            Icons.account_balance_outlined,
            size: 120,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No bank accounts added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Add your first bank account'),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 44,
            child: FilledButton.icon(
              onPressed: _addAccount,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Account'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addAccount() {
    showDialog(
      context: context,
      builder: (context) => _BankAccountDialog(
        onSave: (account) {
          setState(() => _accounts.add(account));
        },
      ),
    );
  }

  void _showAccountDetails(BankAccount account, int index) {
    showDialog(
      context: context,
      builder: (context) => _BankAccountDialog(
        account: account,
        onSave: (updatedAccount) {
          setState(() => _accounts[index] = updatedAccount);
        },
        onDelete: () {
          setState(() => _accounts.removeAt(index));
        },
      ),
    );
  }
}

class BankAccount {
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final double balance;

  BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.balance,
  });
}

class _BankAccountDialog extends StatefulWidget {
  final BankAccount? account;
  final Function(BankAccount) onSave;
  final VoidCallback? onDelete;

  const _BankAccountDialog({
    this.account,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<_BankAccountDialog> {
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountHolderController;
  late TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(text: widget.account?.bankName ?? '');
    _accountNumberController = TextEditingController(text: widget.account?.accountNumber ?? '');
    _accountHolderController = TextEditingController(text: widget.account?.accountHolder ?? '');
    _balanceController = TextEditingController(text: widget.account?.balance.toString() ?? '0');
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? 'Add Bank Account' : 'Edit Bank Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountHolderController,
              decoration: const InputDecoration(
                labelText: 'Account Holder',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Balance',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
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
            final account = BankAccount(
              bankName: _bankNameController.text,
              accountNumber: _accountNumberController.text,
              accountHolder: _accountHolderController.text,
              balance: double.tryParse(_balanceController.text) ?? 0,
            );
            widget.onSave(account);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
