import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/app_header.dart';
import '../models/product_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import 'item_settings_page.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  int _selectedIndex = 2;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
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
                (constraints.maxWidth * 0.04).clamp(12.0, 32.0);
            final contentWidth = constraints.maxWidth - (horizontalPadding * 2);
            final bottomGutter = mediaPadding.bottom +
                16 +
                (constraints.maxWidth < 600 ? kBottomNavigationBarHeight : 0);

            return productsAsync.when(
              data: (products) {
                final slivers = <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildQuickLinks(context, maxWidth: contentWidth),
                    ),
                  ),
                ];

                if (products.isEmpty) {
                  slivers.add(
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          bottomGutter,
                        ),
                        child: _buildEmptyState(
                          context,
                          maxWidth: contentWidth,
                        ),
                      ),
                    ),
                  );
                } else {
                  slivers.add(
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return SizedBox(
                              height: 56,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  CategoryChip(
                                    label: 'All',
                                    isSelected: selectedCategory == null,
                                    onSelected: () {
                                      ref
                                          .read(
                                            selectedCategoryProvider.notifier,
                                          )
                                          .clear();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ...categories.map(
                                    (category) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: CategoryChip(
                                        label: category,
                                        isSelected:
                                            selectedCategory == category,
                                        onSelected: () {
                                          ref
                                              .read(
                                                selectedCategoryProvider
                                                    .notifier,
                                              )
                                              .setCategory(category);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );

                  slivers.add(
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        bottomGutter,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveBuilder(
                          mobile: _buildMobileList(
                            products,
                            padding: EdgeInsets.zero,
                          ),
                          tablet: _buildTabletGrid(
                            products,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return CustomScrollView(slivers: slivers);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(width < 380 ? 16 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: width < 360 ? 48 : 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading items',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(productsStreamProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddProduct(context),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
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

  Widget _buildQuickLinks(BuildContext context, {required double maxWidth}) {
    final isCompact = maxWidth < 380;
    final iconSize = isCompact ? 22.0 : 24.0;

    final items = <({IconData icon, String label})>[
      (icon: Icons.storefront_outlined, label: 'Online store'),
      (icon: Icons.trending_up_outlined, label: 'Stock summary'),
      (icon: Icons.settings_outlined, label: 'Item settings'),
      (icon: Icons.apps_outlined, label: 'Show All'),
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
                final itemWidth = (constraints.maxWidth / 4).clamp(78.0, 120.0);
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
                              case 'Item settings':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ItemSettingsPage(),
                                  ),
                                );
                                return;
                              case 'Stock summary':
                                context.go('/reports');
                                return;
                              case 'Online store':
                                _showMessage(context, 'Online store coming soon');
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
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFF1F3F8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: iconSize,
                                    color: const Color(0xFF2E2E2E),
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

  Widget _buildEmptyState(BuildContext context, {required double maxWidth}) {
    final isCompact = maxWidth < 380;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: isCompact ? 120 : 140,
          color: const Color(0xFFC9A47A).withValues(alpha: 0.75),
        ),
        const SizedBox(height: 18),
        Text(
          'Hey! You have not added any items yet. Add\nyour first item now.',
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 180,
          height: 44,
          child: FilledButton(
            onPressed: () => _navigateToAddProduct(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add New Item',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(
    List<ProductModel> products, {
    required EdgeInsets padding,
  }) {
    return ListView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductCard(
            product: product,
            onTap: () => _navigateToProductDetail(context, product.id),
            onEdit: () => _navigateToEditProduct(context, product),
            onDelete: () => _confirmDelete(context, product),
          ),
        );
      },
    );
  }

  Widget _buildTabletGrid(
    List<ProductModel> products, {
    required EdgeInsets padding,
  }) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => _navigateToProductDetail(context, product.id),
          onEdit: () => _navigateToEditProduct(context, product),
          onDelete: () => _confirmDelete(context, product),
        );
      },
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductFormScreen(),
      ),
    );
  }

  void _navigateToEditProduct(BuildContext context, ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  void _navigateToProductDetail(BuildContext context, int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
          .read(productActionsProvider.notifier)
          .deleteProduct(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Product deleted successfully'
                  : 'Failed to delete product',
            ),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
