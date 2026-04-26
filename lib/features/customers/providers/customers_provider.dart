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
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(customersRepositoryProvider);
      final id = await repository.insertCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        panNumber: panNumber,
        balance: balance,
      );
      
      ref.invalidate(customersStreamProvider);
      
      return id;
    }).then((asyncValue) {
      state = asyncValue;
      return asyncValue.value ?? 0;
    });
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(customersRepositoryProvider);
      final success = await repository.updateCustomer(customer);
      
      ref.invalidate(customersStreamProvider);
      ref.invalidate(customerProvider(customer.id));
      
      return success;
    }).then((asyncValue) {
      state = asyncValue;
      return asyncValue.value ?? false;
    });
  }

  Future<bool> deleteCustomer(int id) async {
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(customersRepositoryProvider);
      final result = await repository.deleteCustomer(id);
      
      ref.invalidate(customersStreamProvider);
      
      return result > 0;
    }).then((asyncValue) {
      state = asyncValue;
      return asyncValue.value ?? false;
    });
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
