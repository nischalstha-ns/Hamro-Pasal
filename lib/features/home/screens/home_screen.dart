import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/services/reminder_service.dart';
import '../../settings/screens/tax_settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedHomeTab = 0;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showTransactionDialog(BuildContext context) async {
    // Navigate to new sale form screen
    context.push('/sale/new');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AdaptiveLayout(
      showNavigationRail: true,
      navigationRail: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          _handleNavigation(context, index);
        },
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
        appBar: const AppHeader(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final mediaPadding = MediaQuery.paddingOf(context);
            final horizontalPadding =
                (constraints.maxWidth * 0.05).clamp(12.0, 24.0);
            final bottomGutter = mediaPadding.bottom +
                16 +
                (constraints.maxWidth < 600 ? kBottomNavigationBarHeight : 0);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                bottomGutter,
              ),
              child: Column(
                children: [
                  _buildHomeTabs(context, width),
                  const SizedBox(height: 14),
                  _buildQuickLinks(context, width),
                  const SizedBox(height: 24),
                  _selectedHomeTab == 0
                      ? _buildTransactionsList(context, width)
                      : _buildPartyDetails(context, width),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(
            _selectedHomeTab == 0 ? '/sale/new' : '/party/add',
          ),
          backgroundColor: const Color(0xFF1DB954),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              return const SizedBox.shrink();
            }
            return NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                _handleNavigation(context, index);
              },
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
            );
          },
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/dashboard');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/menu');
        break;
    }
  }

  Widget _buildHomeTabs(BuildContext context, double width) {
    final isCompact = width < 380;
    const selectedColor = Color(0xFFE21B22);
    const unselectedColor = Colors.white;
    const borderColor = Color(0xFFCBD6F2);

    Widget buildTab(String label, int index) {
      final isSelected = _selectedHomeTab == index;
      final background = isSelected ? selectedColor : unselectedColor;
      final textColor = isSelected ? Colors.white : const Color(0xFF8C95A6);

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _selectedHomeTab = index),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 10 : 12,
              horizontal: 12,
            ),
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

    return Row(
      children: [
        buildTab('Transaction Details', 0),
        const SizedBox(width: 12),
        buildTab('Party Details', 1),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context, double width) {
    final isCompact = width < 380;
    final iconSize = isCompact ? 22.0 : 24.0;

    final items = <({IconData icon, String label, Color? iconColor})>[
      (
        icon: Icons.insert_chart_outlined,
        label: 'Sale Report',
        iconColor: null
      ),
      (
        icon: Icons.percent,
        label: 'Tax Settings',
        iconColor: null
      ),
      (
        icon: Icons.workspace_premium,
        label: 'Upgrade',
        iconColor: const Color(0xFF1D9E75)
      ),
      (icon: Icons.apps_outlined, label: 'Show All', iconColor: null),
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Links',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth / 4).clamp(72.0, 110.0);
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 12,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: itemWidth,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            switch (item.label) {
                              case 'Sale Report':
                                context.go('/reports');
                                return;
                              case 'Tax Settings':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TaxSettingsScreen(),
                                  ),
                                );
                                return;
                              case 'Upgrade':
                                _showPremiumDialog(context);
                                return;
                              default:
                                _showMessage(context, 'Coming soon');
                                return;
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.iconColor != null
                                        ? item.iconColor!
                                            .withValues(alpha: 0.12)
                                        : const Color(0xFFF1F3F8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: iconSize,
                                    color: item.iconColor ??
                                        const Color(0xFF2E2E2E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFFFD700),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Premium Features',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upgrade to Premium and unlock:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem('Unlimited transactions & invoices'),
              _buildFeatureItem('Cloud backup & sync across devices'),
              _buildFeatureItem('Advanced reports & analytics'),
              _buildFeatureItem('Multi-user access & permissions'),
              _buildFeatureItem('Priority customer support'),
              _buildFeatureItem('Custom invoice templates'),
              _buildFeatureItem('Inventory management'),
              _buildFeatureItem('Online store integration'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFBDEB6D).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBDEB6D)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎉 EARLY BIRD OFFER',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                        children: [
                          TextSpan(text: 'Only '),
                          TextSpan(
                            text: 'Rs. 999/year',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF1D9E75),
                            ),
                          ),
                          TextSpan(text: '\n'),
                          TextSpan(
                            text: '(Regular price: Rs. 1,999)',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage(context, 'Payment integration coming soon!');
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF1D9E75),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double width) {
    final isCompact = width < 380;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: isCompact ? 110 : 130,
            color: const Color(0xFF2F66D5).withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            'Hey! You have not added any transactions\nyet. Add your first transaction now.',
            textAlign: TextAlign.center,
            style: titleStyle,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 44,
            child: FilledButton.icon(
              onPressed: () => _showTransactionDialog(context),
              icon: const Icon(Icons.currency_rupee, size: 18),
              label: const Text(
                'Add New Sale',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, double width) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(context, width);
        }

        // Filter only sales
        final sales = transactions.where((t) => t.type == 'sale').toList();
        
        if (sales.isEmpty) {
          return _buildEmptyState(context, width);
        }

        return Column(
          children: sales.take(5).map((transaction) {
            return _buildTransactionCard(context, transaction, width);
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Error loading transactions',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel transaction,
    double width,
  ) {
    final isCompact = width < 380;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/transactions'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: isCompact ? 44 : 48,
                height: isCompact ? 44 : 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.green,
                  size: isCompact ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.customerName ?? 'Unknown Customer',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatBS(transaction.transactionDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
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
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SALE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildPartyDetails(BuildContext context, double width) {
    final customersAsync = ref.watch(customersStreamProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return customersAsync.when(
      data: (customers) {
        return transactionsAsync.when(
          data: (transactions) {
            // Create a map to store party data
            final Map<String, ({double balance, DateTime lastDate})> partyData = {};

            // Add all customers from database
            for (final customer in customers) {
              partyData[customer.name] = (
                balance: customer.balance,
                lastDate: customer.updatedAt,
              );
            }

            // Update with transaction data
            for (final transaction in transactions) {
              if (transaction.customerName != null && transaction.customerName!.isNotEmpty) {
                final name = transaction.customerName!;
                final existing = partyData[name];
                
                if (existing != null) {
                  // Update existing customer
                  partyData[name] = (
                    balance: existing.balance + transaction.totalAmount,
                    lastDate: transaction.transactionDate.isAfter(existing.lastDate)
                        ? transaction.transactionDate
                        : existing.lastDate,
                  );
                } else {
                  // Add new customer from transaction
                  partyData[name] = (
                    balance: transaction.totalAmount,
                    lastDate: transaction.transactionDate,
                  );
                }
              }
            }

            if (partyData.isEmpty) {
              return _buildPartyEmptyState(context, width);
            }

            // Sort by name
            final sortedParties = partyData.keys.toList()..sort();

            return Column(
              children: sortedParties.map((partyName) {
                final data = partyData[partyName]!;
                return _buildPartyCard(
                  context,
                  partyName,
                  data.balance,
                  data.lastDate,
                  width,
                );
              }).toList(),
            );
          },
          loading: () => _buildPartiesFromCustomersOnly(customers, width),
          error: (_, __) => _buildPartiesFromCustomersOnly(customers, width),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Error loading parties',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildPartiesFromCustomersOnly(List<CustomerModel> customers, double width) {
    if (customers.isEmpty) {
      return _buildPartyEmptyState(context, width);
    }

    final sortedCustomers = customers.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: sortedCustomers.map((customer) {
        return _buildPartyCard(
          context,
          customer.name,
          customer.balance,
          customer.updatedAt,
          width,
        );
      }).toList(),
    );
  }

  Widget _buildPartyCard(
    BuildContext context,
    String customerName,
    double balance,
    DateTime lastDate,
    double width,
  ) {
    final isCompact = width < 380;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/customers'),
        onLongPress: balance < 0 ? () => _showReminderOptions(context, customerName, balance) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatBS(lastDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(balance),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                  ),
                  if (balance < 0) ...[
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.notifications_active, size: 20),
                      color: const Color(0xFFFF9800),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showReminderOptions(context, customerName, balance),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReminderOptions(BuildContext context, String customerName, double balance) async {
    final customersStream = ref.read(customersStreamProvider);
    
    customersStream.when(
      data: (customers) {
        final customer = customers.firstWhere(
          (c) => c.name == customerName,
          orElse: () => CustomerModel(
            id: 0,
            name: customerName,
            balance: balance,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (!context.mounted) return;

        _showReminderBottomSheet(context, customer, balance);
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _showReminderBottomSheet(BuildContext context, CustomerModel customer, double balance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Payment Reminder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'To: ${customer.name}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                'Amount: ${CurrencyFormatter.format(balance.abs())}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366)),
                ),
                title: const Text('WhatsApp'),
                subtitle: Text(customer.phone ?? 'No phone number'),
                trailing: const Icon(Icons.chevron_right),
                onTap: customer.phone != null
                    ? () async {
                        Navigator.pop(context);
                        final success = await ReminderService.sendWhatsAppReminder(
                          customer: customer,
                          amount: balance.abs(),
                        );
                        if (context.mounted) {
                          _showMessage(
                            context,
                            success ? 'Opening WhatsApp...' : 'Failed to open WhatsApp',
                          );
                        }
                      }
                    : null,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7360F2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone, color: Color(0xFF7360F2)),
                ),
                title: const Text('Viber'),
                subtitle: Text(customer.phone ?? 'No phone number'),
                trailing: const Icon(Icons.chevron_right),
                onTap: customer.phone != null
                    ? () async {
                        Navigator.pop(context);
                        final success = await ReminderService.sendViberReminder(
                          customer: customer,
                          amount: balance.abs(),
                        );
                        if (context.mounted) {
                          _showMessage(
                            context,
                            success ? 'Opening Viber...' : 'Failed to open Viber',
                          );
                        }
                      }
                    : null,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.message, color: Color(0xFF2196F3)),
                ),
                title: const Text('SMS'),
                subtitle: Text(customer.phone ?? 'No phone number'),
                trailing: const Icon(Icons.chevron_right),
                onTap: customer.phone != null
                    ? () async {
                        Navigator.pop(context);
                        final success = await ReminderService.sendSMSReminder(
                          customer: customer,
                          amount: balance.abs(),
                        );
                        if (context.mounted) {
                          _showMessage(
                            context,
                            success ? 'Opening SMS...' : 'Failed to open SMS',
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartyEmptyState(BuildContext context, double width) {
    final isCompact = width < 380;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: isCompact ? 110 : 130,
            color: const Color(0xFF2F66D5).withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            'No parties found.\nAdd transactions with customer names to see them here.',
            textAlign: TextAlign.center,
            style: titleStyle,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 44,
            child: FilledButton.icon(
              onPressed: () => context.push('/party/add'),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text(
                'Add New Party',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
