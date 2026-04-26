import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../models/customer_model.dart';

class CustomersRepository {
  CustomersRepository(this._database);

  final AppDatabase _database;

  Future<List<CustomerModel>> getAllCustomers() async {
    final customers = await _database.getAllCustomers();
    return customers.map(_toModel).toList();
  }

  Stream<List<CustomerModel>> watchAllCustomers() {
    return _database.watchAllCustomers().map(
          (customers) => customers.map(_toModel).toList(),
        );
  }

  Future<CustomerModel?> getCustomerById(int id) async {
    final customer = await _database.getCustomerById(id);
    return customer != null ? _toModel(customer) : null;
  }

  Stream<List<CustomerModel>> searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    return _database.watchAllCustomers().map(
          (customers) => customers
              .where(
                (c) =>
                    c.name.toLowerCase().contains(lowerQuery) ||
                    (c.phone?.toLowerCase().contains(lowerQuery) ?? false) ||
                    (c.email?.toLowerCase().contains(lowerQuery) ?? false),
              )
              .map(_toModel)
              .toList(),
        );
  }

  Stream<List<CustomerModel>> watchCustomersWithBalance() {
    return _database.watchAllCustomers().map(
          (customers) => customers
              .where((c) => c.balance != 0 && c.isActive)
              .map(_toModel)
              .toList(),
        );
  }

  Future<int> insertCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? panNumber,
    double? balance,
  }) async {
    return await _database.insertCustomer(
      CustomersCompanion.insert(
        name: name,
        phone: Value(phone),
        email: Value(email),
        address: Value(address),
        panNumber: Value(panNumber),
        balance: Value(balance ?? 0.0),
      ),
    );
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    return await _database.updateCustomer(
      Customer(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        panNumber: customer.panNumber,
        balance: customer.balance,
        isActive: customer.isActive,
        createdAt: customer.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<int> deleteCustomer(int id) async {
    return await _database.deleteCustomer(id);
  }

  Future<bool> toggleActiveStatus(int id, bool isActive) async {
    final customer = await _database.getCustomerById(id);
    if (customer == null) return false;

    return await _database.updateCustomer(
      customer.copyWith(isActive: isActive, updatedAt: DateTime.now()),
    );
  }

  Future<bool> updateBalance(int id, double newBalance) async {
    final customer = await _database.getCustomerById(id);
    if (customer == null) return false;

    return await _database.updateCustomer(
      customer.copyWith(balance: newBalance, updatedAt: DateTime.now()),
    );
  }

  CustomerModel _toModel(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      panNumber: customer.panNumber,
      balance: customer.balance,
      isActive: customer.isActive,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }
}
