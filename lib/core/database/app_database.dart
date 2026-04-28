import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get nameNepali => text().withLength(max: 200).nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get barcode => text().withLength(max: 50).nullable()();
  TextColumn get sku => text().withLength(max: 50).nullable()();
  RealColumn get price => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get category => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  
  // Dynamic Variants
  BoolColumn get hasVariants => boolean().withDefault(const Constant(false))();
  TextColumn get variantOptions => text().nullable()(); // JSON string like {"Size": ["S","M"], "Color": ["Red"]}

  DateTimeColumn get expiryDate => dateTime().nullable()();
  BoolColumn get expiryAlertEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get expiryAlertDays => integer().withDefault(const Constant(7))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get phone => text().withLength(max: 15).nullable()();
  TextColumn get email => text().withLength(max: 100).nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get panNumber => text().withLength(max: 9).nullable()();
  RealColumn get balance => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().withLength(max: 50)();
  TextColumn get type => text()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  TextColumn get customerPan => text().nullable()();
  RealColumn get amount => real()();
  RealColumn get vatAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get attachments => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  TextColumn get selectedVariant => text().nullable()(); // E.g., "Size: M, Color: Red"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Products, Customers, Transactions, TransactionItems, Settings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async => await m.createAll(),
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) await m.addColumn(transactions, transactions.attachments);
        if (from < 3) await m.addColumn(transactions, transactions.customerName);
        if (from < 4) {
          await m.addColumn(transactions, transactions.customerPhone);
          await m.addColumn(transactions, transactions.customerAddress);
          await m.addColumn(transactions, transactions.customerPan);
        }
        if (from < 5) {
          await m.addColumn(products, products.expiryDate);
          await m.addColumn(products, products.expiryAlertEnabled);
          await m.addColumn(products, products.expiryAlertDays);
        }
        if (from < 6) {
          await m.addColumn(products, products.hasVariants);
          await m.addColumn(products, products.variantOptions);
          await m.addColumn(transactionItems, transactionItems.selectedVariant);
        }
      },
    );
  }

  Future<List<Product>> getAllProducts() => select(products).get();
  Stream<List<Product>> watchAllProducts() => select(products).watch();
  Future<Product?> getProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);
  Future<bool> updateProduct(Product product) =>
      update(products).replace(product);
  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  Future<List<Customer>> getAllCustomers() => select(customers).get();
  Stream<List<Customer>> watchAllCustomers() => select(customers).watch();
  Future<Customer?> getCustomerById(int id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();
  Future<int> insertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer);
  Future<bool> updateCustomer(Customer customer) =>
      update(customers).replace(customer);
  Future<int> deleteCustomer(int id) =>
      (delete(customers)..where((c) => c.id.equals(id))).go();

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Stream<List<Transaction>> watchAllTransactions() => select(transactions).watch();
  Future<Transaction?> getTransactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);
  Future<int> insertTransactionItem(TransactionItemsCompanion item) =>
      into(transactionItems).insert(item);
  Future<List<TransactionItem>> getItemsForTransaction(int transactionId) =>
      (select(transactionItems)
            ..where((i) => i.transactionId.equals(transactionId)))
          .get();
  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<double> getTotalSalesByDateRange(DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.totalAmount.sum()])
      ..where(transactions.type.equals('sale'))
      ..where(transactions.transactionDate.isBiggerOrEqualValue(start))
      ..where(transactions.transactionDate.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(transactions.totalAmount.sum()) ?? 0.0;
  }

  Future<int> getTransactionCountByDateRange(
      DateTime start, DateTime end, String type) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where(transactions.type.equals(type))
      ..where(transactions.transactionDate.isBiggerOrEqualValue(start))
      ..where(transactions.transactionDate.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(transactions.id.count()) ?? 0;
  }

  Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.totalAmount.sum()])
      ..where(transactions.type.equals('expense'))
      ..where(transactions.transactionDate.isBiggerOrEqualValue(start))
      ..where(transactions.transactionDate.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(transactions.totalAmount.sum()) ?? 0.0;
  }

  Stream<List<Transaction>> watchTransactionsByType(String type) =>
      (select(transactions)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .watch();

  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }
}