import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/services/data_import_service.dart';
import '../../../core/services/data_backup_service.dart';
import '../../../core/services/data_restore_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/models/backup_models.dart';
import '../../products/providers/products_provider.dart';
import '../providers/data_management_provider.dart';
import '../widgets/progress_dialog.dart';
import '../widgets/import_preview_sheet.dart';

final historyServiceProvider = Provider((ref) => HistoryService());

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ImportHistoryRecord> _importHistory = [];
  List<ExportHistoryRecord> _exportHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final historyService = ref.read(historyServiceProvider);
    final imports = await historyService.getImportHistory();
    final exports = await historyService.getExportHistory();
    if (mounted) {
      setState(() {
        _importHistory = imports;
        _exportHistory = exports;
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Hamro Pasal Backup');
  }

  Future<void> _exportAllAsZip() async {
    final db = ref.read(appDatabaseProvider);
    ref.read(dataOperationProvider.notifier).reset();

    final backupService = DataBackupService(db);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Creating Full Backup (ZIP)',
        operation: () => backupService.createFullBackup(),
        onDone: (result) async {
          if (result is BackupResultInfo) {
            if (result.result == BackupResult.success) {
              final historyService = ref.read(historyServiceProvider);
              await historyService.addExportRecord(ExportHistoryRecord(
                id: generateExportId(),
                fileName: result.fileName,
                exportedAt: DateTime.now(),
                productsExported: result.productCount,
                customersExported: result.customerCount,
                transactionsExported: result.transactionCount,
                success: true,
              ));
              await _loadHistory();

              _showSnack('Backup created: ${result.productCount} products, ${result.categoryCount} categories, ${result.customerCount} customers');

              final file = File(result.filePath);
              await _shareFile(file);
            } else {
              _showSnack('Backup failed: ${result.errors.join(", ")}', isError: true);
            }
          }
        },
      ),
    );
  }

  Future<void> _exportFastExcel() async {
    final db = ref.read(appDatabaseProvider);
    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Exporting Data (Excel Fast)',
        operation: () =>
            ref.read(dataOperationProvider.notifier).exportExcel(db, ExportMode.fast),
        onDone: (result) {
          if (result is File) _shareFile(result);
        },
      ),
    );
  }

Future<void> _startImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'csv', 'xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final file = File(result.files.first.path!);
    final ext = file.path.split('.').last.toLowerCase();

    if (ext == 'zip') {
      await _importZip(file);
    } else if (ext == 'csv') {
      await _importCsv(file);
    } else {
      await _importExcel(file);
    }
  }

  Future<void> _importCsv(File file) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('What are you importing?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.orange),
              title: const Text('Products'),
              onTap: () => Navigator.pop(ctx, 'products'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text('Customers'),
              onTap: () => Navigator.pop(ctx, 'customers'),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    ImportPreview preview;
    try {
      final importService = DataImportService(db);
      preview = await importService.parseFile(file, chosen);
    } catch (e) {
      _showSnack('Failed to parse file: $e', isError: true);
      return;
    }

    if (!mounted) return;

    final confirmed = await ImportPreviewSheet.show(context, preview);
    if (confirmed != true || !mounted) return;

    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Importing ${chosen[0].toUpperCase()}${chosen.substring(1)}',
        operation: () => ref.read(dataOperationProvider.notifier).runImport(db, preview),
        onDone: (result) async {
          if (result is ImportResult) {
            final historyService = ref.read(historyServiceProvider);
            await historyService.addImportRecord(ImportHistoryRecord(
              id: generateImportId(),
              fileName: file.path.split('/').last.split('\\').last,
              importedAt: DateTime.now(),
              type: chosen.toUpperCase(),
              productsImported: chosen == 'products' ? result.imported : 0,
              productsSkipped: chosen == 'products' ? result.failed : 0,
              customersImported: chosen == 'customers' ? result.imported : 0,
              customersSkipped: chosen == 'customers' ? result.failed : 0,
              success: result.failed == 0,
              errorMessage: result.errors.isNotEmpty ? result.errors.first : null,
            ));
            await _loadHistory();

            _showSnack(
              'Imported ${result.imported} records. Failed: ${result.failed}',
              isError: result.failed > 0,
            );
          }
        },
      ),
    );
  }

  Future<void> _importExcel(File file) async {
    final db = ref.read(appDatabaseProvider);
    ImportPreview preview;
    try {
      final importService = DataImportService(db);
      preview = await importService.parseFile(file, 'all');
    } catch (e) {
      _showSnack('Failed to parse file: $e', isError: true);
      return;
    }

    if (!mounted) return;

    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Importing Data',
        operation: () => ref.read(dataOperationProvider.notifier).runImport(db, preview),
        onDone: (result) async {
          if (result is ImportResult) {
            final historyService = ref.read(historyServiceProvider);
            await historyService.addImportRecord(ImportHistoryRecord(
              id: generateImportId(),
              fileName: file.path.split('/').last.split('\\').last,
              importedAt: DateTime.now(),
              type: 'EXCEL',
              productsImported: result.imported,
              productsSkipped: result.failed,
              customersImported: 0,
              customersSkipped: 0,
              success: result.failed == 0,
              errorMessage: result.errors.isNotEmpty ? result.errors.first : null,
            ));
            await _loadHistory();

            _showSnack(
              'Imported ${result.imported} records. Failed: ${result.failed}',
              isError: result.failed > 0,
            );
          }
        },
      ),
    );
  }
  }

  Future<void> _importZip(File file) async {
    final db = ref.read(appDatabaseProvider);

    final duplicateOption = await showDialog<DuplicateHandling>(
      context: context,
      builder: (ctx) => _DuplicateHandlingDialog(
        title: 'Duplicate Products',
        onSelect: (option) => Navigator.pop(ctx, option),
      ),
    );
    if (duplicateOption == null || !mounted) return;

    final options = ImportOptions(
      productHandling: duplicateOption,
      customerHandling: duplicateOption,
    );

    final restoreService = DataRestoreService(db);
    final historyService = ref.read(historyServiceProvider);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Restoring from Backup',
        operation: () => restoreService.restoreFromZip(file.path, options: options),
        onDone: (result) async {
          if (result is RestoreResultInfo) {
            final fileName = file.path.split('/').last.split('\\').last;

            await historyService.addImportRecord(ImportHistoryRecord(
              id: generateImportId(),
              fileName: fileName,
              importedAt: DateTime.now(),
              type: 'ZIP Backup',
              productsImported: result.productsImported,
              productsSkipped: result.productsSkipped,
              customersImported: result.customersImported,
              customersSkipped: result.customersSkipped,
              success: result.result != RestoreResult.failed,
              errorMessage: result.errors.isNotEmpty ? result.errors.join(", ") : null,
            ));
            await _loadHistory();

            if (result.result == RestoreResult.success) {
              _showSnack(
                'Restored: ${result.productsImported} products, ${result.customersImported} customers',
              );
            } else if (result.result == RestoreResult.partialSuccess) {
              _showSnack(
                'Partial restore: ${result.productsImported} imported, ${result.productsSkipped} skipped',
                isError: true,
              );
            } else {
              _showSnack('Restore failed: ${result.errors.join(", ")}', isError: true);
            }
          }
        },
      ),
    );
  }

  Future<void> _importOther(File file, String ext) async {
    String chosen = 'all';
    
    if (ext != 'zip') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      if (result == null || result.files.isEmpty || !mounted) return;

      if (result.files.first.extension == 'csv') {
        chosen = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('What are you importing?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.orange),
                  title: const Text('Products'),
                  onTap: () => Navigator.pop(ctx, 'products'),
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.blue),
                  title: const Text('Customers'),
                  onTap: () => Navigator.pop(ctx, 'customers'),
                ),
              ],
            ),
          ),
        );
        if (chosen == null || !mounted) return;
      }
    }

    final db = ref.read(appDatabaseProvider);
    ImportPreview preview;
    try {
      final importService = DataImportService(db);
      preview = await importService.parseFile(file, chosen);
    } catch (e) {
      _showSnack('Failed to parse file: $e', isError: true);
      return;
    }

    if (!mounted) return;

    final confirmed = await ImportPreviewSheet.show(context, preview);
    if (confirmed != true || !mounted) return;

    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Importing ${chosen[0].toUpperCase()}${chosen.substring(1)}',
        operation: () => ref.read(dataOperationProvider.notifier).runImport(db, preview),
        onDone: (result) async {
          if (result is ImportResult) {
            final historyService = ref.read(historyServiceProvider);
            await historyService.addImportRecord(ImportHistoryRecord(
              id: generateImportId(),
              fileName: file.path.split('/').last.split('\\').last,
              importedAt: DateTime.now(),
              type: chosen.toUpperCase(),
              productsImported: chosen == 'products' ? result.imported : 0,
              productsSkipped: chosen == 'products' ? result.failed : 0,
              customersImported: chosen == 'customers' ? result.imported : 0,
              customersSkipped: chosen == 'customers' ? result.failed : 0,
              success: result.failed == 0,
              errorMessage: result.errors.isNotEmpty ? result.errors.first : null,
            ));
            await _loadHistory();

            _showSnack(
              'Imported ${result.imported} records. Failed: ${result.failed}',
              isError: result.failed > 0,
            );
          }
        },
      ),
    );
  }

  Future<void> _reImportBackup(String fileName) async {
    final historyService = ref.read(historyServiceProvider);
    final file = await historyService.getBackupFile(fileName);
    if (file == null) {
      _showSnack('Backup file not found', isError: true);
      return;
    }
    await _importZip(file);
  }

  Future<void> _deleteHistoryRecord(String id, bool isImport) async {
    final historyService = ref.read(historyServiceProvider);
    if (isImport) {
      await historyService.deleteImportRecord(id);
    } else {
      await historyService.deleteExportRecord(id);
    }
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Import & Export', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Transfer'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransferTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildTransferTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Export Data', Icons.upload_file, const Color(0xFF4CAF50)),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.archive_outlined,
                  title: 'Full Backup (ZIP)',
                  subtitle: 'Export all data with images in one file',
                  color: const Color(0xFF4CAF50),
                  onTap: _exportAllAsZip,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.table_chart_outlined,
                  title: 'Fast Excel Export',
                  subtitle: 'Generates .xlsx without images',
                  color: const Color(0xFF4CAF50),
                  onTap: _exportFastExcel,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Import Data', Icons.download_outlined, const Color(0xFFFF9800)),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.restore,
                  title: 'Restore from Backup',
                  subtitle: 'Import ZIP backup with images & settings',
                  color: const Color(0xFFFF9800),
                  onTap: _startImport,
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.file_open_outlined,
                  title: 'Import Excel/CSV',
                  subtitle: 'Import Products or Customers',
                  color: const Color(0xFFFF9800),
                  onTap: _startImport,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Backup Files', Icons.folder_outlined, const Color(0xFF2196F3)),
        _buildBackupFilesList(),
      ],
    );
  }

  Widget _buildBackupFilesList() {
    return FutureBuilder<List<File>>(
      future: ref.read(historyServiceProvider).getAllBackupFiles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No backup files found', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final file = snapshot.data![index];
              final fileName = file.path.split('/').last.split('\\').last;
              return ListTile(
                leading: const Icon(Icons.folder_zip, color: Color(0xFF4CAF50)),
                title: Text(fileName, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  'Tap to restore',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                onTap: () => _reImportBackup(fileName),
                trailing: PopupMenuButton(
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Restore'),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Share'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'restore') {
                      await _reImportBackup(fileName);
                    } else if (value == 'share') {
                      await _shareFile(file);
                    } else if (value == 'delete') {
                      await ref.read(historyServiceProvider).deleteBackupFile(fileName);
                      setState(() {});
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Import History', Icons.download, const Color(0xFFFF9800)),
        if (_importHistory.isEmpty)
          _buildEmptyHistoryCard('No import history')
        else
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _importHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = _importHistory[index];
                return _HistoryTile(
                  record: record,
                  isImport: true,
                  onDelete: () => _deleteHistoryRecord(record.id, true),
                  onReImport: () => _reImportBackup(record.fileName),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        _buildSectionHeader('Export History', Icons.upload, const Color(0xFF4CAF50)),
        if (_exportHistory.isEmpty)
          _buildEmptyHistoryCard('No export history')
        else
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exportHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = _exportHistory[index];
                return _ExportHistoryTile(
                  record: record,
                  onDelete: () => _deleteHistoryRecord(record.id, false),
                  onShare: () => _shareFileFromHistory(record),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyHistoryCard(String message) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message, style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  Future<void> _shareFileFromHistory(ExportHistoryRecord record) async {
    final historyService = ref.read(historyServiceProvider);
    final file = await historyService.getBackupFile(record.fileName);
    if (file != null) {
      await _shareFile(file);
    } else {
      _showSnack('Backup file not found', isError: true);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ImportHistoryRecord record;
  final bool isImport;
  final VoidCallback onDelete;
  final VoidCallback onReImport;

  const _HistoryTile({
    required this.record,
    required this.isImport,
    required this.onDelete,
    required this.onReImport,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        record.success ? Icons.check_circle : Icons.error,
        color: record.success ? Colors.green : Colors.red,
      ),
      title: Text(record.fileName, style: const TextStyle(fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(record.importedAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            'Products: ${record.productsImported} | Customers: ${record.customersImported}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton(
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'reimport', child: Text('Re-import')),
          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
        onSelected: (value) {
          if (value == 'reimport') onReImport();
          if (value == 'delete') onDelete();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ExportHistoryTile extends StatelessWidget {
  final ExportHistoryRecord record;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _ExportHistoryTile({
    required this.record,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        record.success ? Icons.check_circle : Icons.error,
        color: record.success ? Colors.green : Colors.red,
      ),
      title: Text(record.fileName, style: const TextStyle(fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(record.exportedAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            'Products: ${record.productsExported} | Customers: ${record.customersExported}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton(
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'share', child: Text('Share')),
          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
        onSelected: (value) {
          if (value == 'share') onShare();
          if (value == 'delete') onDelete();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DuplicateHandlingDialog extends StatelessWidget {
  final String title;
  final Function(DuplicateHandling) onSelect;

  const _DuplicateHandlingDialog({required this.title, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.skip_next, color: Colors.grey),
            title: const Text('Skip Duplicates'),
            subtitle: const Text('Keep existing products'),
            onTap: () => onSelect(DuplicateHandling.skip),
          ),
          ListTile(
            leading: const Icon(Icons.merge, color: Colors.blue),
            title: const Text('Merge Stock'),
            subtitle: const Text('Add stock to existing products'),
            onTap: () => onSelect(DuplicateHandling.merge),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.orange),
            title: const Text('Replace'),
            subtitle: const Text('Overwrite existing products'),
            onTap: () => onSelect(DuplicateHandling.replace),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}