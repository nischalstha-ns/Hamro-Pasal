import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/transaction_model.dart';
import '../repositories/transactions_repository.dart';
import '../../products/providers/products_provider.dart';

part 'transactions_provider.g.dart';

@riverpod
TransactionsRepository transactionsRepository(TransactionsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionsRepository(db);
}

@riverpod
Stream<List<TransactionModel>> transactionsStream(TransactionsStreamRef ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.watchAllTransactions();
}

@riverpod
Future<TransactionModel?> transactionById(
  TransactionByIdRef ref,
  int id,
) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.getTransactionById(id);
}

@riverpod
Future<List<TransactionModel>> transactionsByCustomer(
  TransactionsByCustomerRef ref,
  int customerId,
) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.getTransactionsByCustomer(customerId);
}

@riverpod
class TransactionActions extends _$TransactionActions {
  @override
  FutureOr<void> build() {}

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final repository = ref.read(transactionsRepositoryProvider);
      await repository.insertTransaction(transaction);
      ref.invalidate(transactionsStreamProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> addTransactionWithItems({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
  }) async {
    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final id = await repository.insertTransactionWithItems(
        transaction: transaction,
        items: items,
      );
      ref.invalidate(transactionsStreamProvider);
      return id;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final repository = ref.read(transactionsRepositoryProvider);
      final result = await repository.deleteTransaction(id);
      ref.invalidate(transactionsStreamProvider);
      return result > 0;
    } catch (e) {
      return false;
    }
  }
}

@riverpod
class TransactionFilter extends _$TransactionFilter {
  @override
  String? build() => null;

  void setFilter(String? filter) => state = filter;
  void clear() => state = null;
}

@riverpod
Future<List<TransactionModel>> filteredTransactions(
  FilteredTransactionsRef ref,
) async {
  final transactionsAsync = await ref.watch(transactionsStreamProvider.future);
  final filter = ref.watch(transactionFilterProvider);

  if (filter == null || filter.isEmpty) {
    return transactionsAsync;
  }

  return transactionsAsync
      .where((t) =>
          t.type.toLowerCase() == filter.toLowerCase() ||
          t.invoiceNumber.toLowerCase().contains(filter.toLowerCase()),)
      .toList();
}
