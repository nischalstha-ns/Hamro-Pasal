import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../products/providers/products_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 1;

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
            final contentWidth = constraints.maxWidth - (horizontalPadding * 2);
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
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildBusinessInsights(context, maxWidth: contentWidth),
                        const SizedBox(height: 16),
                        _buildProfitLossTracking(context, maxWidth: contentWidth),
                        const SizedBox(height: 16),
                        _buildStockTracking(context, maxWidth: contentWidth),
                        const SizedBox(height: 16),
                        _buildRevenueAnalysis(context, maxWidth: contentWidth),
                        const SizedBox(height: 16),
                        _buildSaleOverview(context, maxWidth: contentWidth),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    bottomGutter,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildAddNewSaleButton(context, maxWidth: contentWidth),
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

  Widget _buildBusinessInsights(BuildContext context, {required double maxWidth}) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isCompact = maxWidth < 380;

    double totalRevenue = 0;
    double totalExpenses = 0;
    double totalProfit = 0;
    int totalOrders = 0;

    transactionsAsync.whenData((transactions) {
      final adNow = DateTime.now();
      final monthStart = DateTime(adNow.year, adNow.month, 1);

      for (final t in transactions) {
        if (t.transactionDate.isAfter(monthStart) ||
            t.transactionDate.isAtSameMomentAs(monthStart)) {
          if (t.type == 'sale') {
            totalRevenue += t.totalAmount;
            totalOrders++;
          } else if (t.type == 'expense' || t.type == 'purchase') {
            totalExpenses += t.totalAmount;
          }
        }
      }
      totalProfit = totalRevenue - totalExpenses;
    });

    final insights = [
      (
        icon: Icons.trending_up,
        label: 'Revenue',
        value: CurrencyFormatter.format(totalRevenue),
        color: const Color(0xFF1DB954),
        bgColor: const Color(0xFFE8F5E9),
      ),
      (
        icon: Icons.account_balance_wallet,
        label: 'Profit',
        value: CurrencyFormatter.format(totalProfit),
        color: totalProfit >= 0 ? const Color(0xFF2196F3) : const Color(0xFFE21B22),
        bgColor: totalProfit >= 0 ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
      ),
      (
        icon: Icons.money_off,
        label: 'Expenses',
        value: CurrencyFormatter.format(totalExpenses),
        color: const Color(0xFFFF9800),
        bgColor: const Color(0xFFFFF3E0),
      ),
      (
        icon: Icons.shopping_cart,
        label: 'Orders',
        value: '$totalOrders',
        color: const Color(0xFF9C27B0),
        bgColor: const Color(0xFFF3E5F5),
      ),
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Business Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: maxWidth < 600 ? 2 : 4,
                childAspectRatio: maxWidth < 600 ? 1.5 : 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: insight.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: insight.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          insight.icon,
                          color: insight.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          insight.value,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: insight.color,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTracking(BuildContext context, {required double maxWidth}) {
    final productsAsync = ref.watch(productsStreamProvider);
    final isCompact = maxWidth < 380;

    return productsAsync.when(
      data: (products) {
        int totalItems = products.length;
        int lowStockItems = products.where((p) => p.stock <= p.minStock).length;
        int outOfStockItems = products.where((p) => p.stock == 0).length;
        double totalStockValue = products.fold(0.0, (sum, p) => sum + (p.stock * p.costPrice));

        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stock Tracking',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/stock-tracking'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStockItem(
                        context,
                        'Total Items',
                        '$totalItems',
                        Icons.inventory,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStockItem(
                        context,
                        'Low Stock',
                        '$lowStockItems',
                        Icons.warning_amber_rounded,
                        const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStockItem(
                        context,
                        'Out of Stock',
                        '$outOfStockItems',
                        Icons.remove_circle_outline,
                        const Color(0xFFE21B22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStockItem(
                        context,
                        'Stock Value',
                        CurrencyFormatter.format(totalStockValue),
                        Icons.account_balance_wallet,
                        const Color(0xFF1DB954),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStockItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalysis(BuildContext context, {required double maxWidth}) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isCompact = maxWidth < 380;

    double todaySales = 0;
    double weekSales = 0;
    double monthSales = 0;
    int todayOrders = 0;
    int weekOrders = 0;

    transactionsAsync.whenData((transactions) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      for (final t in transactions) {
        if (t.type == 'sale') {
          if (t.transactionDate.isAfter(todayStart) ||
              t.transactionDate.isAtSameMomentAs(todayStart)) {
            todaySales += t.totalAmount;
            todayOrders++;
          }
          if (t.transactionDate.isAfter(weekStart) ||
              t.transactionDate.isAtSameMomentAs(weekStart)) {
            weekSales += t.totalAmount;
            weekOrders++;
          }
          if (t.transactionDate.isAfter(monthStart) ||
              t.transactionDate.isAtSameMomentAs(monthStart)) {
            monthSales += t.totalAmount;
          }
        }
      }
    });

    final avgOrderValue = todayOrders > 0 ? (todaySales / todayOrders).toDouble() : 0.0;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Revenue Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    context,
                    'Today',
                    CurrencyFormatter.format(todaySales),
                    '$todayOrders orders',
                    const Color(0xFF1DB954),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueItem(
                    context,
                    'This Week',
                    CurrencyFormatter.format(weekSales),
                    '$weekOrders orders',
                    const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    context,
                    'This Month',
                    CurrencyFormatter.format(monthSales),
                    'Total sales',
                    const Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueItem(
                    context,
                    'Avg Order',
                    CurrencyFormatter.format(avgOrderValue),
                    'Per order',
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleOverview(BuildContext context, {required double maxWidth}) {
    final isCompact = maxWidth < 380;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final headerStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final amountStyle = (isCompact
            ? Theme.of(context).textTheme.headlineSmall
            : Theme.of(context).textTheme.headlineMedium)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1DB954),
    );
    final captionStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF1DB954),
          fontWeight: FontWeight.w600,
        );

    const bsMonths = [
      'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
      'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
    ];
    final now = NepaliDateTime.now();
    final currentMonth = bsMonths[now.month - 1];
    final prevMonth1 = bsMonths[(now.month - 2) % 12];
    final prevMonth2 = bsMonths[(now.month - 3) % 12];

    final transactionsAsync = ref.watch(transactionsStreamProvider);
    double totalSales = 0;
    double prevMonthSales = 0;

    transactionsAsync.whenData((transactions) {
      final adNow = DateTime.now();
      final monthStart = DateTime(adNow.year, adNow.month, 1);
      final prevMonthStart = DateTime(adNow.year, adNow.month - 1, 1);

      for (final t in transactions) {
        if (t.type == 'sale') {
          if (t.transactionDate.isAfter(monthStart) ||
              t.transactionDate.isAtSameMomentAs(monthStart)) {
            totalSales += t.totalAmount;
          } else if (t.transactionDate.isAfter(prevMonthStart)) {
            prevMonthSales += t.totalAmount;
          }
        }
      }
    });

    final growthPct = prevMonthSales > 0
        ? (((totalSales - prevMonthSales) / prevMonthSales) * 100).round()
        : (totalSales > 0 ? 100 : 0);
    final isGrowth = growthPct >= 0;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Sale Overview ($currentMonth)', style: titleStyle),
            SizedBox(height: isCompact ? 14 : 18),
            Center(
              child: Column(
                children: [
                  Text('Total Sale', style: headerStyle),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(totalSales),
                      style: amountStyle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: (isGrowth
                                  ? const Color(0xFF1DB954)
                                  : Colors.red)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGrowth
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: isGrowth
                              ? const Color(0xFF1DB954)
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${growthPct.abs()}% ${isGrowth ? "More" : "Less"} Growth This Month',
                        style: captionStyle?.copyWith(
                          color: isGrowth
                              ? const Color(0xFF1DB954)
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isCompact ? 18 : 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D8BFF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(prevMonth2,
                    style: Theme.of(context).textTheme.labelSmall,),
                Text(prevMonth1,
                    style: Theme.of(context).textTheme.labelSmall,),
                Text(currentMonth,
                    style: Theme.of(context).textTheme.labelSmall,),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitLossTracking(BuildContext context, {required double maxWidth}) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final isCompact = maxWidth < 380;

    return transactionsAsync.when(
      data: (transactions) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        double revenue = 0;
        double cogs = 0;
        double expenses = 0;

        for (final t in transactions) {
          if (t.transactionDate.isAfter(monthStart) ||
              t.transactionDate.isAtSameMomentAs(monthStart)) {
            if (t.type == 'sale') {
              revenue += t.totalAmount;
              // COGS is cost price * quantity for sold items
              cogs += (t.totalAmount * 0.6); // Approximate 60% COGS
            } else if (t.type == 'expense') {
              expenses += t.totalAmount;
            }
          }
        }

        final grossProfit = revenue - cogs;
        final netProfit = grossProfit - expenses;
        final grossMargin = revenue > 0 ? (grossProfit / revenue * 100).toDouble() : 0.0;
        final netMargin = revenue > 0 ? (netProfit / revenue * 100).toDouble() : 0.0;

        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assessment,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Profit & Loss (This Month)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPLRow(context, 'Revenue', revenue, const Color(0xFF1DB954), isBold: true),
                const SizedBox(height: 8),
                _buildPLRow(context, 'Cost of Goods Sold', cogs, const Color(0xFFFF9800), isNegative: true),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 8),
                _buildPLRow(
                  context,
                  'Gross Profit',
                  grossProfit,
                  grossProfit >= 0 ? const Color(0xFF2196F3) : const Color(0xFFE21B22),
                  isBold: true,
                  showMargin: true,
                  margin: grossMargin,
                ),
                const SizedBox(height: 8),
                _buildPLRow(context, 'Operating Expenses', expenses, const Color(0xFFE21B22), isNegative: true),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300], thickness: 2),
                const SizedBox(height: 8),
                _buildPLRow(
                  context,
                  'Net Profit',
                  netProfit,
                  netProfit >= 0 ? const Color(0xFF1DB954) : const Color(0xFFE21B22),
                  isBold: true,
                  isLarge: true,
                  showMargin: true,
                  margin: netMargin,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPLRow(
    BuildContext context,
    String label,
    double amount,
    Color color, {
    bool isBold = false,
    bool isLarge = false,
    bool isNegative = false,
    bool showMargin = false,
    double margin = 0,
  }) {
    final displayAmount = isNegative ? -amount : amount;
    final formattedAmount = CurrencyFormatter.format(displayAmount.abs());
    final prefix = isNegative ? '- ' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isLarge ? 16 : 14,
                  color: Colors.grey[800],
                ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix$formattedAmount',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    fontSize: isLarge ? 18 : 14,
                    color: color,
                  ),
            ),
            if (showMargin)
              Text(
                '${margin.toStringAsFixed(1)}% margin',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddNewSaleButton(
    BuildContext context, {
    required double maxWidth,
  }) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 180,
        height: 44,
        child: FilledButton.icon(
          onPressed: () => context.push('/sale/new'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Add New Sale',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
