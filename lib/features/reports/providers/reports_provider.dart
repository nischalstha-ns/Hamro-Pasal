import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../customers/providers/customers_provider.dart';

part 'reports_provider.g.dart';

@riverpod
class SalesReports extends _$SalesReports {
  @override
  FutureOr<Map<String, dynamic>> build() async {
    return _calculateReports();
  }

  Future<Map<String, dynamic>> _calculateReports() async {
    final transactions = await ref.read(transactionsStreamProvider.future);
    final customers = await ref.read(customersStreamProvider.future);

    final sales = transactions.where((t) => t.type == 'sale').toList();
    final totalSales = sales.fold(0.0, (sum, t) => sum + t.totalAmount);
    final totalOrders = sales.length;

    // Daily sales for chart (last 7 days)
    final now = DateTime.now();
    final salesByDay = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayTotal = sales
          .where((t) =>
              t.transactionDate.isAfter(dayStart) &&
              t.transactionDate.isBefore(dayEnd),)
          .fold(0.0, (sum, t) => sum + t.totalAmount);
      salesByDay.add({
        'date': dayStart,
        'amount': dayTotal,
        'dayIndex': i,
      });
    }

    // Top products: aggregate by product from transaction items
    final productSales = <String, double>{};
    for (final sale in sales) {
      if (sale.items.isNotEmpty) {
        for (final item in sale.items) {
          productSales[item.productName] =
              (productSales[item.productName] ?? 0) + item.totalPrice;
        }
      }
    }
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top customers by transaction volume
    final customerSales = <String, double>{};
    for (final sale in sales) {
      final name = sale.customerName ?? 'Walk-in';
      customerSales[name] = (customerSales[name] ?? 0) + sale.totalAmount;
    }
    final topCustomers = customerSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'totalCustomers': customers.length,
      'topProducts': topProducts.take(5).toList(),
      'topCustomers': topCustomers.take(5).toList(),
      'salesByDay': salesByDay,
    };
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _calculateReports());
  }
}
