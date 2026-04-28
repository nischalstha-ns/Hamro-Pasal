import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../products/providers/products_provider.dart';
import '../models/customer_model.dart';
import '../repositories/customers_repository.dart';

part 'customers_provider.g.dart';

@riverpod
CustomersRepository customersRepository(CustomersRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  return CustomersRepository(database);
}

@riverpod
Stream<List<CustomerModel>> customersStream(CustomersStreamRef ref) {
  final repository = ref.watch(customersRepositoryProvider);
  return repository.watchAllCustomers();
}

@riverpod
Stream<List<CustomerModel>> customersWithBalance(CustomersWithBalanceRef ref) {
  final repository = ref.watch(customersRepositoryProvider);
  return repository.watchCustomersWithBalance();
}

@riverpod
class CustomerSearchQuery extends _$CustomerSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

@riverpod
Stream<List<CustomerModel>> filteredCustomers(FilteredCustomersRef ref) {
  final repository = ref.watch(customersRepositoryProvider);
  final searchQuery = ref.watch(customerSearchQueryProvider);

  if (searchQuery.isEmpty) {
    return repository.watchAllCustomers();
  }

  return repository.searchCustomers(searchQuery);
}

@riverpod
Future<CustomerModel?> customer(CustomerRef ref, int id) async {
  final repository = ref.watch(customersRepositoryProvider);
  return await repository.getCustomerById(id);
}

@riverpod
class CustomerActions extends _$CustomerActions {
  @override
  FutureOr<void> build() {}

  Future<int> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? panNumber,
    double? balance,
  }) async {
    int resultId = 0;
    try {
      final repository = ref.read(customersRepositoryProvider);
      resultId = await repository.insertCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        panNumber: panNumber,
        balance: balance,
      );
      ref.invalidate(customersStreamProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
    return resultId;
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    bool success = false;
    try {
      final repository = ref.read(customersRepositoryProvider);
      success = await repository.updateCustomer(customer);
      ref.invalidate(customersStreamProvider);
      ref.invalidate(customerProvider(customer.id));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
    return success;
  }

  Future<bool> deleteCustomer(int id) async {
    bool result = false;
    try {
      final repository = ref.read(customersRepositoryProvider);
      final rows = await repository.deleteCustomer(id);
      result = rows > 0;
      ref.invalidate(customersStreamProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
    return result;
  }

  Future<bool> toggleActiveStatus(int id, bool isActive) async {
    final repository = ref.read(customersRepositoryProvider);
    final success = await repository.toggleActiveStatus(id, isActive);
    
    if (success) {
      ref.invalidate(customersStreamProvider);
      ref.invalidate(customerProvider(id));
    }
    
    return success;
  }

  Future<bool> updateBalance(int id, double newBalance) async {
    final repository = ref.read(customersRepositoryProvider);
    final success = await repository.updateBalance(id, newBalance);
    
    if (success) {
      ref.invalidate(customersStreamProvider);
      ref.invalidate(customerProvider(id));
    }
    
    return success;
  }
}
