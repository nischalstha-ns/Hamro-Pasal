import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/providers/products_provider.dart';
import '../../products/models/product_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'low_stock', child: Text('Low Stock')),
              const PopupMenuItem(value: 'expiry', child: Text('Expiry Alerts')),
            ],
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final notifications = _buildNotifications(products);
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return notifications[index];
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading notifications',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNotifications(List<ProductModel> products) {
    final List<Widget> notifications = [];
    final now = DateTime.now();

    if (_selectedFilter == 'all' || _selectedFilter == 'low_stock') {
      final lowStockProducts = products.where((p) => p.stock <= p.minStock && p.stock > 0).toList();
      
      for (final product in lowStockProducts) {
        notifications.add(
          _buildNotificationCard(
            context: context,
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF9800),
            title: 'Low Stock Alert',
            message: '${product.name} is running low. Current stock: ${product.stock} ${product.unit}',
            time: 'Now',
            onTap: () => context.push('/products/${product.id}/edit', extra: product),
          ),
        );
      }

      final outOfStockProducts = products.where((p) => p.stock == 0).toList();
      
      for (final product in outOfStockProducts) {
        notifications.add(
          _buildNotificationCard(
            context: context,
            icon: Icons.remove_circle_outline,
            iconColor: const Color(0xFFE21B22),
            title: 'Out of Stock',
            message: '${product.name} is out of stock. Please restock immediately.',
            time: 'Now',
            onTap: () => context.push('/products/${product.id}/edit', extra: product),
          ),
        );
      }
    }

    if (_selectedFilter == 'all' || _selectedFilter == 'expiry') {
      final expiringProducts = products.where((p) {
        if (!p.expiryAlertEnabled || p.expiryDate == null) return false;
        final daysUntilExpiry = p.expiryDate!.difference(now).inDays;
        return daysUntilExpiry <= p.expiryAlertDays && daysUntilExpiry >= 0;
      }).toList();

      for (final product in expiringProducts) {
        final daysLeft = product.expiryDate!.difference(now).inDays;
        notifications.add(
          _buildNotificationCard(
            context: context,
            icon: Icons.event_busy,
            iconColor: const Color(0xFFFF5722),
            title: 'Expiry Alert',
            message: '${product.name} will expire in $daysLeft day${daysLeft == 1 ? '' : 's'}',
            time: 'Now',
            onTap: () => context.push('/products/${product.id}/edit', extra: product),
          ),
        );
      }

      final expiredProducts = products.where((p) {
        if (p.expiryDate == null) return false;
        return p.expiryDate!.isBefore(now);
      }).toList();

      for (final product in expiredProducts) {
        notifications.add(
          _buildNotificationCard(
            context: context,
            icon: Icons.dangerous,
            iconColor: const Color(0xFFE21B22),
            title: 'Product Expired',
            message: '${product.name} has expired. Remove from inventory.',
            time: 'Now',
            onTap: () => context.push('/products/${product.id}/edit', extra: product),
          ),
        );
      }
    }

    return notifications;
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
