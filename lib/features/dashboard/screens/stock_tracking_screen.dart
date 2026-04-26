import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../../products/providers/products_provider.dart';
import '../../products/models/product_model.dart';

class StockTrackingScreen extends ConsumerStatefulWidget {
  const StockTrackingScreen({super.key});

  @override
  ConsumerState<StockTrackingScreen> createState() => _StockTrackingScreenState();
}

class _StockTrackingScreenState extends ConsumerState<StockTrackingScreen> {
  int _selectedIndex = 1;
  String _selectedFilter = 'all';

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
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Stock Tracking',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStockSummary(context),
                        const SizedBox(height: 16),
                        _buildFilterChips(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    bottomGutter,
                  ),
                  sliver: _buildProductsList(context),
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

  Widget _buildStockSummary(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      data: (products) {
        int totalItems = products.length;
        int lowStockItems = products.where((p) => p.stock <= p.minStock && p.stock > 0).length;
        int outOfStockItems = products.where((p) => p.stock == 0).length;
        double totalStockValue = products.fold(0.0, (sum, p) => sum + (p.stock * p.costPrice));
        int inStockItems = products.where((p) => p.stock > p.minStock).length;

        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Total Items',
                        '$totalItems',
                        Icons.inventory,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'In Stock',
                        '$inStockItems',
                        Icons.check_circle,
                        const Color(0xFF1DB954),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Low Stock',
                        '$lowStockItems',
                        Icons.warning_amber_rounded,
                        const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Out of Stock',
                        '$outOfStockItems',
                        Icons.remove_circle_outline,
                        const Color(0xFFE21B22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Stock Value',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(totalStockValue),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1DB954),
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF1DB954),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryCard(
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      ('all', 'All Items', Icons.inventory),
      ('in_stock', 'In Stock', Icons.check_circle),
      ('low_stock', 'Low Stock', Icons.warning_amber_rounded),
      ('out_of_stock', 'Out of Stock', Icons.remove_circle_outline),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filter.$3, size: 16),
                  const SizedBox(width: 6),
                  Text(filter.$2),
                ],
              ),
              onSelected: (selected) {
                setState(() => _selectedFilter = filter.$1);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1D9E75).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF1D9E75),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return productsAsync.when(
      data: (products) {
        List<ProductModel> filteredProducts = products;

        switch (_selectedFilter) {
          case 'in_stock':
            filteredProducts = products.where((p) => p.stock > p.minStock).toList();
            break;
          case 'low_stock':
            filteredProducts = products.where((p) => p.stock <= p.minStock && p.stock > 0).toList();
            break;
          case 'out_of_stock':
            filteredProducts = products.where((p) => p.stock == 0).toList();
            break;
        }

        if (filteredProducts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(context, product);
            },
            childCount: filteredProducts.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error loading products',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final stockStatus = _getStockStatus(product);
    final stockValue = product.stock * product.costPrice;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/products/${product.id}/edit', extra: product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (product.category != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.category!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: stockStatus.$3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stockStatus.$2, size: 14, color: stockStatus.$3),
                        const SizedBox(width: 4),
                        Text(
                          stockStatus.$1,
                          style: TextStyle(
                            color: stockStatus.$3,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Current Stock',
                      '${product.stock} ${product.unit}',
                      Icons.inventory_2,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Min Stock',
                      '${product.minStock} ${product.unit}',
                      Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Cost Price',
                      CurrencyFormatter.format(product.costPrice),
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Stock Value',
                      CurrencyFormatter.format(stockValue),
                      Icons.account_balance_wallet,
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

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  (String, IconData, Color) _getStockStatus(ProductModel product) {
    if (product.stock == 0) {
      return ('Out of Stock', Icons.remove_circle_outline, const Color(0xFFE21B22));
    } else if (product.stock <= product.minStock) {
      return ('Low Stock', Icons.warning_amber_rounded, const Color(0xFFFF9800));
    } else {
      return ('In Stock', Icons.check_circle, const Color(0xFF1DB954));
    }
  }
}
