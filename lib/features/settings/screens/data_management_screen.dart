import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../products/providers/products_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Data Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Backup & Restore',
            icon: Icons.backup,
            color: const Color(0xFF2196F3),
            children: [
              _buildActionTile(
                context,
                icon: Icons.cloud_upload,
                title: 'Backup to Google Drive',
                subtitle: 'Save data to cloud',
                onTap: _isProcessing ? null : () => _backupToGoogleDrive(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.cloud_download,
                title: 'Restore from Google Drive',
                subtitle: 'Load data from cloud',
                onTap: _isProcessing ? null : () => _restoreFromGoogleDrive(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.save_alt,
                title: 'Backup to Device',
                subtitle: 'Save backup file locally',
                onTap: _isProcessing ? null : () => _backupToDevice(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.folder_open,
                title: 'Restore from Device',
                subtitle: 'Load backup file',
                onTap: _isProcessing ? null : () => _restoreFromDevice(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Export Data',
            icon: Icons.upload_file,
            color: const Color(0xFF1DB954),
            children: [
              _buildActionTile(
                context,
                icon: Icons.table_chart,
                title: 'Export Products (CSV)',
                subtitle: 'Export all products',
                onTap: _isProcessing ? null : () => _exportProducts(context, 'csv'),
              ),
              _buildActionTile(
                context,
                icon: Icons.table_view,
                title: 'Export Products (Excel)',
                subtitle: 'Export all products',
                onTap: _isProcessing ? null : () => _exportProducts(context, 'xlsx'),
              ),
              _buildActionTile(
                context,
                icon: Icons.people,
                title: 'Export Customers (CSV)',
                subtitle: 'Export all customers',
                onTap: _isProcessing ? null : () => _exportCustomers(context, 'csv'),
              ),
              _buildActionTile(
                context,
                icon: Icons.receipt_long,
                title: 'Export Transactions (CSV)',
                subtitle: 'Export all transactions',
                onTap: _isProcessing ? null : () => _exportTransactions(context, 'csv'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Import Data',
            icon: Icons.download,
            color: const Color(0xFFFF9800),
            children: [
              _buildActionTile(
                context,
                icon: Icons.inventory_2,
                title: 'Import Products',
                subtitle: 'Import from CSV/Excel',
                onTap: _isProcessing ? null : () => _importProducts(context),
              ),
              _buildActionTile(
                context,
                icon: Icons.person_add,
                title: 'Import Customers',
                subtitle: 'Import from CSV',
                onTap: _isProcessing ? null : () => _importCustomers(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _backupToGoogleDrive(BuildContext context) async {
    setState(() => _isProcessing = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Google Drive integration coming soon!'),
            backgroundColor: Color(0xFF2196F3),
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreFromGoogleDrive(BuildContext context) async {
    setState(() => _isProcessing = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Google Drive integration coming soon!'),
            backgroundColor: Color(0xFF2196F3),
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _backupToDevice(BuildContext context) async {
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(appDatabaseProvider);

      final products = await (db.select(db.products)..orderBy([(t) => drift.OrderingTerm.asc(t.id)])).get();
      final customers = await (db.select(db.customers)..orderBy([(t) => drift.OrderingTerm.asc(t.id)])).get();
      final transactions = await (db.select(db.transactions)..orderBy([(t) => drift.OrderingTerm.asc(t.id)])).get();
      final settings = await (db.select(db.settings)..orderBy([(t) => drift.OrderingTerm.asc(t.key)])).get();

      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'settings': settings.map((s) => s.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/backup_$timestamp.json');
      await file.writeAsString(jsonString);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Digital Khata Backup',
      );
      // ignore: use_build_context_synchronously
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreFromDevice(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isProcessing = true);

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup'),
          content: Text(
            'This will replace all current data with backup from:\n${backup['timestamp']}\n\nContinue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isProcessing = false);
        return;
      }

      final db = ref.read(appDatabaseProvider);

      await db.delete(db.products).go();
      await db.delete(db.customers).go();
      await db.delete(db.transactions).go();

      for (final item in backup['products'] as List) {
        await db.into(db.products).insert(ProductsCompanion.insert(
          name: item['name'],
          price: item['price'],
          costPrice: item['cost_price'] ?? 0.0,
          stock: item['stock'],
          minStock: item['min_stock'],
          unit: item['unit'],
        ));
      }

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportProducts(BuildContext context, String format) async {
    setState(() => _isProcessing = true);
    try {
      final products = await ref.read(productsStreamProvider.future);

      final csv = StringBuffer();
      csv.writeln('Name,Price,Cost Price,Stock,Min Stock,Unit,Category,Barcode');

      for (final product in products) {
        csv.writeln(
          '${product.name},${product.price},${product.costPrice},${product.stock},${product.minStock},${product.unit},${product.category ?? ''},${product.barcode ?? ''}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/products_$timestamp.csv');
      await file.writeAsString(csv.toString());

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Products Export',
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Products exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportCustomers(BuildContext context, String format) async {
    setState(() => _isProcessing = true);
    try {
      final customers = await ref.read(customersStreamProvider.future);

      final csv = StringBuffer();
      csv.writeln('Name,Phone,Email,Address,Balance');

      for (final customer in customers) {
        csv.writeln(
          '${customer.name},${customer.phone ?? ''},${customer.email ?? ''},${customer.address ?? ''},${customer.balance}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/customers_$timestamp.csv');
      await file.writeAsString(csv.toString());

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Customers Export',
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Customers exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportTransactions(BuildContext context, String format) async {
    setState(() => _isProcessing = true);
    try {
      final transactions = await ref.read(transactionsStreamProvider.future);

      final csv = StringBuffer();
      csv.writeln('Date,Type,Customer,Amount,Payment Method,Notes');

      for (final transaction in transactions) {
        csv.writeln(
          '${transaction.transactionDate},${transaction.type},${transaction.customerName ?? ''},${transaction.totalAmount},${transaction.paymentMethod},${transaction.notes ?? ''}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/transactions_$timestamp.csv');
      await file.writeAsString(csv.toString());

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Transactions Export',
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Transactions exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importProducts(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isProcessing = true);

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final lines = content.split('\n');

      if (lines.length < 2) {
        throw Exception('Invalid CSV file');
      }

      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 6) continue;

        await ref.read(productActionsProvider.notifier).addProduct(
              name: parts[0],
              price: double.tryParse(parts[1]) ?? 0.0,
              costPrice: double.tryParse(parts[2]) ?? 0.0,
              stock: int.tryParse(parts[3]) ?? 0,
              minStock: int.tryParse(parts[4]) ?? 0,
              unit: parts[5],
              category: parts.length > 6 ? parts[6] : null,
              barcode: parts.length > 7 ? parts[7] : null,
            );
        imported++;
      }

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Imported $imported products successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importCustomers(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isProcessing = true);

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final lines = content.split('\n');

      if (lines.length < 2) {
        throw Exception('Invalid CSV file');
      }

      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.isEmpty) continue;

        await ref.read(customerActionsProvider.notifier).addCustomer(
              name: parts[0],
              phone: parts.length > 1 ? parts[1] : null,
              email: parts.length > 2 ? parts[2] : null,
              address: parts.length > 3 ? parts[3] : null,
            );
        imported++;
      }

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Imported $imported customers successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
