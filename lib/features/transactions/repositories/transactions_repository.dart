import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../models/transaction_model.dart';

class TransactionsRepository {
  final AppDatabase _db;

  TransactionsRepository(this._db);

  Stream<List<TransactionModel>> watchAllTransactions() {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.transactions.customerId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(_db.transactions.transactionDate)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final t = row.readTable(_db.transactions);
        final c = row.readTableOrNull(_db.customers);
        // Use customer name from join if available, otherwise use stored customerName
        final customerName = c?.name ?? t.customerName;
        return _mapToModel(t, customerName: customerName);
      }).toList();
    });
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.transactions.customerId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(_db.transactions.transactionDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final t = row.readTable(_db.transactions);
      final c = row.readTableOrNull(_db.customers);
      // Use customer name from join if available, otherwise use stored customerName
      final customerName = c?.name ?? t.customerName;
      return _mapToModel(t, customerName: customerName);
    }).toList();
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.transactions.customerId),
      ),
    ])
      ..where(_db.transactions.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final t = row.readTable(_db.transactions);
    final c = row.readTableOrNull(_db.customers);
    final items = await _getItemsForTransaction(t.id);
    // Use customer name from join if available, otherwise use stored customerName
    final customerName = c?.name ?? t.customerName;
    return _mapToModel(t, customerName: customerName, items: items);
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    return await _db.insertTransaction(
      TransactionsCompanion.insert(
        invoiceNumber: transaction.invoiceNumber,
        type: transaction.type,
        customerId: Value(transaction.customerId),
        customerName: Value(transaction.customerName),
        customerPhone: Value(transaction.customerPhone),
        customerAddress: Value(transaction.customerAddress),
        customerPan: Value(transaction.customerPan),
        amount: transaction.amount,
        vatAmount: Value(transaction.vatAmount),
        totalAmount: transaction.totalAmount,
        paymentMethod: transaction.paymentMethod,
        notes: Value(transaction.notes),
        attachments: Value(transaction.attachments),
        transactionDate: transaction.transactionDate,
      ),
    );
  }

  Future<int> insertTransactionWithItems({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
  }) async {
    return await _db.transaction(() async {
      final txnId = await _db.insertTransaction(
        TransactionsCompanion.insert(
          invoiceNumber: transaction.invoiceNumber,
          type: transaction.type,
          customerId: Value(transaction.customerId),
          customerName: Value(transaction.customerName),
          customerPhone: Value(transaction.customerPhone),
          customerAddress: Value(transaction.customerAddress),
          customerPan: Value(transaction.customerPan),
          amount: transaction.amount,
          vatAmount: Value(transaction.vatAmount),
          totalAmount: transaction.totalAmount,
          paymentMethod: transaction.paymentMethod,
          notes: Value(transaction.notes),
          attachments: Value(transaction.attachments),
          transactionDate: transaction.transactionDate,
        ),
      );

      for (final item in items) {
        await _db.insertTransactionItem(
          TransactionItemsCompanion.insert(
            transactionId: txnId,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            totalPrice: item.totalPrice,
          ),
        );

        // Deduct stock for sales, add stock for purchases
        if (transaction.type == 'sale') {
          final product = await _db.getProductById(item.productId);
          if (product != null) {
            await (_db.update(_db.products)
                  ..where((p) => p.id.equals(item.productId)))
                .write(ProductsCompanion(
              stock: Value(product.stock - item.quantity),
              updatedAt: Value(DateTime.now()),
            ),);
          }
        } else if (transaction.type == 'purchase') {
          final product = await _db.getProductById(item.productId);
          if (product != null) {
            await (_db.update(_db.products)
                  ..where((p) => p.id.equals(item.productId)))
                .write(ProductsCompanion(
              stock: Value(product.stock + item.quantity),
              updatedAt: Value(DateTime.now()),
            ),);
          }
        }
      }

      // Update customer balance if applicable
      if (transaction.customerId != null) {
        final customer =
            await _db.getCustomerById(transaction.customerId!);
        if (customer != null) {
          double newBalance = customer.balance;
          if (transaction.type == 'sale') {
            newBalance += transaction.totalAmount;
          } else if (transaction.type == 'purchase') {
            newBalance -= transaction.totalAmount;
          } else if (transaction.type == 'payment') {
            newBalance -= transaction.totalAmount;
          } else if (transaction.type == 'receipt') {
            newBalance += transaction.totalAmount;
          }
          await (_db.update(_db.customers)
                ..where((c) => c.id.equals(transaction.customerId!)))
              .write(CustomersCompanion(
            balance: Value(newBalance),
            updatedAt: Value(DateTime.now()),
          ),);
        }
      }

      return txnId;
    });
  }

  Future<int> deleteTransaction(int id) async {
    return await _db.deleteTransaction(id);
  }

  Future<List<TransactionModel>> getTransactionsByCustomer(
      int customerId,) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.transactions.customerId),
      ),
    ])
      ..where(_db.transactions.customerId.equals(customerId))
      ..orderBy([OrderingTerm.desc(_db.transactions.transactionDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final t = row.readTable(_db.transactions);
      final c = row.readTableOrNull(_db.customers);
      // Use customer name from join if available, otherwise use stored customerName
      final customerName = c?.name ?? t.customerName;
      return _mapToModel(t, customerName: customerName);
    }).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.transactions.customerId),
      ),
    ])
      ..where(_db.transactions.transactionDate.isBiggerOrEqualValue(start))
      ..where(_db.transactions.transactionDate.isSmallerOrEqualValue(end))
      ..orderBy([OrderingTerm.desc(_db.transactions.transactionDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final t = row.readTable(_db.transactions);
      final c = row.readTableOrNull(_db.customers);
      // Use customer name from join if available, otherwise use stored customerName
      final customerName = c?.name ?? t.customerName;
      return _mapToModel(t, customerName: customerName);
    }).toList();
  }

  // Aggregation methods for dashboard/reports
  Future<double> getTotalSales(DateTime start, DateTime end) async {
    return _db.getTotalSalesByDateRange(start, end);
  }

  Future<int> getSalesCount(DateTime start, DateTime end) async {
    return _db.getTransactionCountByDateRange(start, end, 'sale');
  }

  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    return _db.getTotalExpensesByDateRange(start, end);
  }

  Future<List<Map<String, dynamic>>> getDailySales(
      DateTime start, DateTime end,) async {
    final transactions = await getTransactionsByDateRange(start, end);
    final salesByDay = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'sale')) {
      final dayKey =
          '${t.transactionDate.year}-${t.transactionDate.month.toString().padLeft(2, '0')}-${t.transactionDate.day.toString().padLeft(2, '0')}';
      salesByDay[dayKey] = (salesByDay[dayKey] ?? 0) + t.totalAmount;
    }
    return salesByDay.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList();
  }

  Future<List<TransactionItemModel>> _getItemsForTransaction(
      int transactionId,) async {
    final items = await _db.getItemsForTransaction(transactionId);
    final result = <TransactionItemModel>[];
    for (final item in items) {
      final product = await _db.getProductById(item.productId);
      result.add(TransactionItemModel(
        id: item.id,
        transactionId: item.transactionId,
        productId: item.productId,
        productName: product?.name ?? 'Unknown Product',
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
      ),);
    }
    return result;
  }

  TransactionModel _mapToModel(
    Transaction t, {
    String? customerName,
    List<TransactionItemModel>? items,
  }) {
    return TransactionModel(
      id: t.id,
      invoiceNumber: t.invoiceNumber,
      type: t.type,
      customerId: t.customerId,
      customerName: customerName,
      customerPhone: t.customerPhone,
      customerAddress: t.customerAddress,
      customerPan: t.customerPan,
      amount: t.amount,
      vatAmount: t.vatAmount,
      totalAmount: t.totalAmount,
      paymentMethod: t.paymentMethod,
      notes: t.notes,
      attachments: t.attachments,
      transactionDate: t.transactionDate,
      createdAt: t.createdAt,
      items: items ?? [],
    );
  }
}
