import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_card.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final width = MediaQuery.sizeOf(context).width;

    return AdaptiveLayout(
      showNavigationRail: true,
      navigationRail: NavigationRail(
        selectedIndex: _selectedIndex,
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
        appBar: const AppHeader(),
        body: customersAsync.when(
          data: (customers) {
            if (customers.isEmpty) {
              return _buildEmptyState(context, width);
            }
            return _buildCustomersList(customers, width);
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
                  onPressed: () => ref.invalidate(customersStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: width < 600
            ? NavigationBar(
                selectedIndex: _selectedIndex,
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
          onPressed: () => _navigateToAddCustomer(context),
          backgroundColor: const Color(0xFFE21B22),
          foregroundColor: Colors.white,
          child: const Icon(Icons.person_add),
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

  Widget _buildEmptyState(BuildContext context, double width) {
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
              'No customers yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first customer to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _navigateToAddCustomer(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList(List<CustomerModel> customers, double width) {
    final padding = EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + (width < 600 ? kBottomNavigationBarHeight : 0),
    );

    return ListView.builder(
      padding: padding,
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomerCard(
            customer: customer,
            onTap: () => _navigateToCustomerDetail(context, customer.id),
            onEdit: () => _navigateToEditCustomer(context, customer),
            onDelete: () => _confirmDelete(context, customer),
          ),
        );
      },
    );
  }

  void _navigateToAddCustomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
  }

  void _navigateToEditCustomer(BuildContext context, CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(customer: customer),
      ),
    );
  }

  void _navigateToCustomerDetail(BuildContext context, int customerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customerId),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(customerActionsProvider.notifier)
          .deleteCustomer(customer.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Customer deleted' : 'Failed to delete customer',
            ),
          ),
        );
      }
    }
  }
}
