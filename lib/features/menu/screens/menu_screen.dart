import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import 'features_overview_screen.dart';
import 'bank_account_screen.dart';
import 'cash_in_hand_screen.dart';
import 'cheques_screen.dart';
import 'loan_accounts_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _selectedIndex = 3;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  @override
  Widget build(BuildContext context) {
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
                (constraints.maxWidth * 0.04).clamp(12.0, 32.0);
            final bottomGutter = mediaPadding.bottom +
                16 +
                (constraints.maxWidth < 600 ? kBottomNavigationBarHeight : 0);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: _buildPromoCard(context)),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionCard(
                      context,
                      title: 'My Business',
                      items: const [
                        _MenuItemData(
                          icon: Icons.currency_rupee,
                          iconColor: Color(0xFF1D3FBF),
                          label: 'Sales',
                          route: '/sale/new',
                        ),
                        _MenuItemData(
                          icon: Icons.shopping_cart_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Purchase',
                          route: '/purchase/new',
                        ),
                        _MenuItemData(
                          icon: Icons.receipt_long_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Expenses',
                          route: '/expense/new',
                        ),
                        _MenuItemData(
                          icon: Icons.storefront_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'My Online stores',
                        ),
                        _MenuItemData(
                          icon: Icons.description_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Reports',
                          route: '/reports',
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    bottomGutter,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionCard(
                      context,
                      title: 'Cash & Bank',
                      items: const [
                        _MenuItemData(
                          icon: Icons.account_balance_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Bank Account',
                        ),
                        _MenuItemData(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Cash In-Hand',
                        ),
                        _MenuItemData(
                          icon: Icons.receipt_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Cheques',
                        ),
                        _MenuItemData(
                          icon: Icons.volunteer_activism_outlined,
                          iconColor: Color(0xFF2E2E2E),
                          label: 'Loan Accounts',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
        return;
      case 1:
        context.go('/dashboard');
        return;
      case 2:
        context.go('/products');
        return;
      case 3:
        context.go('/menu');
        return;
    }
  }

  Widget _buildPromoCard(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return Card(
      color: const Color(0xFFEFF4FF),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'EARLY BIRD OFFER',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFBDEB6D),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    'HURRY UP',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Now, become a premium HamroByapar and get\nexclusive benefits at all...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showPremiumDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D57FF),
                side: const BorderSide(color: Color(0xFFCBD6F2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Buy Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<_MenuItemData> items,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuRow(context, items[i]),
            if (i != items.length - 1)
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, _MenuItemData item) {
    return InkWell(
      onTap: () {
        if (item.route != null) {
          context.push(item.route!);
        } else {
          switch (item.label) {
            case 'Bank Account':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BankAccountScreen()),
              );
              break;
            case 'Cash In-Hand':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashInHandScreen()),
              );
              break;
            case 'Cheques':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChequesScreen()),
              );
              break;
            case 'Loan Accounts':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoanAccountsScreen()),
              );
              break;
            case 'Show All':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeaturesOverviewScreen()),
              );
              break;
            case 'My Online stores':
              _showMessage(context, 'Online store feature coming soon');
              break;
            default:
              break;
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Icon(
                item.icon,
                size: 20,
                color: item.iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.route,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? route;
}
