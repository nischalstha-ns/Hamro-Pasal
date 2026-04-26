import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  int _selectedIndex = 4;
  final String _selectedFilter = 'all';
  bool _isSelectionMode = false;
  final Set<int> _selectedTransactions = {};
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final width = MediaQuery.sizeOf(context).width;

    return AdaptiveLayout(
      showNavigationRail: true,
      navigationRail: NavigationRail(
        selectedIndex: _selectedIndex > 3 ? 3 : _selectedIndex,
        onDestinationSelected: (index) => _handleNavigation(context, index),
        labelType: NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: Text('Items'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu),
            label: Text('Menu'),
          ),
        ],
      ),
      body: Scaffold(
        backgroundColor: const Color(0xFFDEE6F5),
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: Text('${_selectedTransactions.length} selected'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
                actions: [
                  if (_selectedTransactions.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteSelectedTransactions,
                    ),
                ],
              )
            : const AppHeader(),
        body: Column(
          children: [
            _buildTransactionTabs(context, width),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  final filtered = _filterTransactions(transactions);
                  if (filtered.isEmpty) {
                    return _buildEmptyState(context, width);
                  }
                  if (_selectedTab == 1) {
                    // Party Details tab
                    final grouped = _groupByParty(filtered);
                    if (grouped.isEmpty) {
                      return _buildEmptyPartyState(context, width);
                    }
                    return _buildPartiesList(grouped, width);
                  }
                  // Transaction Details tab
                  return _buildTransactionsList(filtered, width);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(transactionsStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: width < 600
            ? NavigationBar(
                selectedIndex: _selectedIndex > 3 ? 3 : _selectedIndex,
                onDestinationSelected: (index) =>
                    _handleNavigation(context, index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'HOME',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'DASHBOARD',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: 'ITEMS',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu),
                    selectedIcon: Icon(Icons.menu),
                    label: 'MENU',
                  ),
                ],
              )
            : null,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/sale/new'),
          backgroundColor: const Color(0xFF1D9E75),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/dashboard');
      case 2:
        context.go('/products');
      case 3:
        context.go('/menu');
    }
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    // Filter by type
    if (_selectedFilter == 'all') return transactions;
    return transactions.where((t) => t.type == _selectedFilter).toList();
  }

  Map<String, List<TransactionModel>> _groupByParty(List<TransactionModel> transactions) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in transactions) {
      if (t.customerName != null && t.customerName!.isNotEmpty) {
        grouped.putIfAbsent(t.customerName!, () => []).add(t);
      }
    }
    return grouped;
  }

  void _showTransactionTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Transaction Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: const Text('Sale'),
              subtitle: const Text('Record a sale'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction(context, 'sale');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.blue),
              title: const Text('Purchase'),
              subtitle: const Text('Record a purchase'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction(context, 'purchase');
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off, color: Colors.red),
              title: const Text('Expense'),
              subtitle: const Text('Record an expense'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction(context, 'expense');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.orange),
              title: const Text('Payment'),
              subtitle: const Text('Record a payment'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction(context, 'payment');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.purple),
              title: const Text('Receipt'),
              subtitle: const Text('Record a receipt'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddTransaction(context, 'receipt');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTabs(BuildContext context, double width) {
    const selectedColor = Color(0xFFE21B22);
    const unselectedColor = Colors.white;
    const borderColor = Color(0xFFCBD6F2);

    Widget buildTab(String label, int index) {
      final isSelected = _selectedTab == index;
      final background = isSelected ? selectedColor : unselectedColor;
      final textColor = isSelected ? Colors.white : const Color(0xFF8C95A6);

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? selectedColor : borderColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFDEE6F5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          buildTab('Transaction Details', 0),
          const SizedBox(width: 12),
          buildTab('Party Details', 1),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double width) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first transaction to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showTransactionTypeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPartyState(BuildContext context, double width) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No party transactions yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions with customers will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartiesList(
    Map<String, List<TransactionModel>> partiesMap,
    double width,
  ) {
    final padding = EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + (width < 600 ? kBottomNavigationBarHeight + 56 : 0),
    );

    final parties = partiesMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: padding,
      itemCount: parties.length,
      itemBuilder: (context, index) {
        final entry = parties[index];
        final partyName = entry.key;
        final transactions = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPartyCard(context, partyName, transactions),
        );
      },
    );
  }

  Widget _buildPartyCard(
    BuildContext context,
    String partyName,
    List<TransactionModel> transactions,
  ) {
    double toReceive = 0;
    double toPay = 0;
    
    for (final t in transactions) {
      if (t.type == 'sale') {
        toReceive += t.totalAmount;
      } else if (t.type == 'purchase') {
        toPay += t.totalAmount;
      }
    }

    final balance = toReceive - toPay;
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;
    final balanceLabel = balance >= 0 ? 'To Receive' : 'To Pay';

    return Card(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // Show party transactions detail
          _showPartyTransactions(context, partyName, transactions);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      partyName[0].toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partyName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transactions.length} transaction${transactions.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(balance.abs()),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: balanceColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          balanceLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: balanceColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPartyStatItem(
                      context,
                      'Sales',
                      CurrencyFormatter.format(toReceive),
                      Colors.green,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildPartyStatItem(
                      context,
                      'Purchases',
                      CurrencyFormatter.format(toPay),
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartyStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  void _showPartyTransactions(
    BuildContext context,
    String partyName,
    List<TransactionModel> transactions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        partyName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTransactionCard(context, transaction),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<TransactionModel> transactions,
    double width,
  ) {
    final padding = EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + (width < 600 ? kBottomNavigationBarHeight + 56 : 0),
    );

    return ListView.builder(
      padding: padding,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTransactionCard(context, transaction),
        );
      },
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final typeColor = _getTypeColor(transaction.type);
    final typeIcon = _getTypeIcon(transaction.type);
    final isSelected = _selectedTransactions.contains(transaction.id);

    return Card(
      color: Colors.white,
      child: InkWell(
        onTap: () => _isSelectionMode
            ? _toggleSelection(transaction.id)
            : _navigateToTransactionDetail(context, transaction.id),
        onLongPress: () => _enterSelectionMode(transaction.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(transaction.id),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.invoiceNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatBS(transaction.transactionDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (transaction.customerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction.customerName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(transaction.totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.type.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              if (!_isSelectionMode)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTransaction(transaction.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.green;
      case 'purchase':
        return Colors.blue;
      case 'expense':
        return Colors.red;
      case 'payment':
        return Colors.orange;
      case 'receipt':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sale':
        return Icons.shopping_cart;
      case 'purchase':
        return Icons.shopping_bag;
      case 'expense':
        return Icons.money_off;
      case 'payment':
        return Icons.payment;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.receipt_long;
    }
  }

  void _navigateToAddTransaction(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(type: type),
      ),
    );
  }

  void _navigateToTransactionDetail(BuildContext context, int transactionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transactionId: transactionId),
      ),
    );
  }

  void _enterSelectionMode(int transactionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactions.add(transactionId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactions.clear();
    });
  }

  void _toggleSelection(int transactionId) {
    setState(() {
      if (_selectedTransactions.contains(transactionId)) {
        _selectedTransactions.remove(transactionId);
        if (_selectedTransactions.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTransactions.add(transactionId);
      }
    });
  }

  Future<void> _deleteTransaction(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(transactionActionsProvider.notifier).deleteTransaction(transactionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedTransactions() async {
    final count = _selectedTransactions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transactions'),
        content: Text('Are you sure you want to delete $count transaction${count > 1 ? 's' : ''}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final id in _selectedTransactions) {
          await ref.read(transactionActionsProvider.notifier).deleteTransaction(id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count transaction${count > 1 ? 's' : ''} deleted successfully')),
          );
          _exitSelectionMode();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transactions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
