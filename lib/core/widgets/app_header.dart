import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/business_profile_provider.dart';
import '../providers/navigation_history_provider.dart';
import '../../features/products/providers/products_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(businessProfileNotifierProvider);
    final router = GoRouter.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = router.routerDelegate.currentConfiguration.uri.toString();
      ref.read(navigationHistoryNotifierProvider.notifier).push(location);
    });

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: profileAsync.when(
        data: (profile) {
          if (profile.logoPath != null && profile.logoPath!.isNotEmpty) {
            final file = File(profile.logoPath!);
            if (file.existsSync()) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
          }
          return IconButton(
            onPressed: () => context.push('/business-profile'),
            icon: const Icon(Icons.storefront_outlined),
          );
        },
        loading: () => const IconButton(
          onPressed: null,
          icon: Icon(Icons.storefront_outlined),
        ),
        error: (_, __) => IconButton(
          onPressed: () => context.push('/business-profile'),
          icon: const Icon(Icons.storefront_outlined),
        ),
      ),
      title: profileAsync.when(
        data: (profile) => Text(
          profile.businessName.isNotEmpty
              ? profile.businessName
              : 'Business name',
        ),
        loading: () => const Text('Loading...'),
        error: (_, __) => const Text('Business name'),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Color(0xFF1D3FBF),
              size: 20,
            ),
          ),
          onPressed: () => _showPremiumDialog(context),
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined),
              Positioned(
                right: 0,
                top: 0,
                child: Consumer(
                  builder: (context, ref, _) {
                    final productsAsync = ref.watch(productsStreamProvider);
                    return productsAsync.when(
                      data: (products) {
                        final now = DateTime.now();
                        int notificationCount = 0;
                        
                        notificationCount += products.where((p) => p.stock <= p.minStock).length;
                        
                        notificationCount += products.where((p) {
                          if (!p.expiryAlertEnabled || p.expiryDate == null) return false;
                          final daysUntilExpiry = p.expiryDate!.difference(now).inDays;
                          return daysUntilExpiry <= p.expiryAlertDays;
                        }).length;
                        
                        if (notificationCount == 0) return const SizedBox.shrink();
                        
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE21B22),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationCount > 9 ? '9+' : '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          ),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.point_of_sale_outlined),
          tooltip: 'POS System',
          onPressed: () => context.push('/pos'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
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
              _showComingSoon(context);
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
}
