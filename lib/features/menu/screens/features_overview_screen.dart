import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeaturesOverviewScreen extends StatelessWidget {
  const FeaturesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Available Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            context,
            title: 'Products Management',
            description: 'Add, edit, and manage your inventory',
            icon: Icons.inventory_2,
            color: Colors.blue,
            route: '/products',
            isImplemented: true,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Customers Management',
            description: 'Manage customer information and balances',
            icon: Icons.people,
            color: Colors.green,
            route: '/customers',
            isImplemented: true,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Dashboard',
            description: 'View sales overview and statistics',
            icon: Icons.dashboard,
            color: Colors.orange,
            route: '/dashboard',
            isImplemented: true,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Reports & Analytics',
            description: 'View charts and business insights',
            icon: Icons.bar_chart,
            color: Colors.purple,
            route: '/reports',
            isImplemented: true,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Settings',
            description: 'Configure app preferences',
            icon: Icons.settings,
            color: Colors.grey,
            route: '/settings',
            isImplemented: true,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Transactions',
            description: 'Sales, purchases, and payments',
            icon: Icons.receipt_long,
            color: Colors.red,
            route: null,
            isImplemented: false,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            title: 'Backup & Restore',
            description: 'Google Drive backup',
            icon: Icons.backup,
            color: Colors.teal,
            route: null,
            isImplemented: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String? route,
    required bool isImplemented,
  }) {
    return Card(
      color: Colors.white,
      child: InkWell(
        onTap: isImplemented && route != null
            ? () => context.push(route)
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isImplemented)
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
                              'READY',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SOON',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
