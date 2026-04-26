import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.netProfit,
    required this.lowStockCount,
  });

  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double netProfit;
  final int lowStockCount;
}

@riverpod
class DashboardData extends _$DashboardData {
  @override
  Future<DashboardStats> build() async {
    // TODO: Fetch real data from database
    return const DashboardStats(
      totalSales: 125000.00,
      totalPurchases: 75000.00,
      totalExpenses: 15000.00,
      netProfit: 35000.00,
      lowStockCount: 5,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: Fetch fresh data from database
      return const DashboardStats(
        totalSales: 125000.00,
        totalPurchases: 75000.00,
        totalExpenses: 15000.00,
        netProfit: 35000.00,
        lowStockCount: 5,
      );
    });
  }
}
