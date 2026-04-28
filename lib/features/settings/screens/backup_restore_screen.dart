import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/backup_service.dart';
import '../../../core/services/drive_service.dart';
import '../../products/providers/products_provider.dart';
import '../providers/data_management_provider.dart';
import '../widgets/progress_dialog.dart';
import '../widgets/drive_backup_list_sheet.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  String _localPath = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadLocalPath();
  }

  Future<void> _loadLocalPath() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _localPath = dir.path;
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
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/zip')]);
  }

  // ─────────────────────────────────────────────────────
  // LOCAL BACKUP
  // ─────────────────────────────────────────────────────

  Future<void> _createLocalBackup() async {
    final db = ref.read(appDatabaseProvider);
    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Creating Local Backup',
        operation: () => ref.read(dataOperationProvider.notifier).createLocalBackup(db),
        onDone: (result) {
          if (result is File) {
            _shareFile(result);
            _showSnack('✅ Backup saved locally!');
          }
        },
      ),
    );
  }

  Future<void> _restoreFromLocal() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'hpbackup', 'json'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final file = File(result.files.first.path!);

    final db = ref.read(appDatabaseProvider);
    BackupManifest manifest;
    try {
      final svc = BackupService(db);
      manifest = await svc.readManifest(file);
    } catch (e) {
      _showSnack('Invalid backup file: $e', isError: true);
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.restore, color: Color(0xFF2196F3)),
          SizedBox(width: 10),
          Text('Restore Backup'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will REPLACE all existing data. This cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _ManifestRow('Created', manifest.createdAt.substring(0, 19)),
            _ManifestRow('Products', '${manifest.productCount}'),
            _ManifestRow('Customers', '${manifest.customerCount}'),
            _ManifestRow('Transactions', '${manifest.transactionCount}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Restoring from Local Backup',
        operation: () => ref.read(dataOperationProvider.notifier).restoreLocalBackup(db, file),
        onDone: (result) {
          if (result is RestoreResult) {
            _showSnack(
                '✅ Restored ${result.products} products, ${result.customers} customers, ${result.transactions} transactions');
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // GOOGLE DRIVE
  // ─────────────────────────────────────────────────────

  Future<void> _driveSignIn() async {
    final success = await ref.read(driveAuthProvider.notifier).signIn();
    if (!success && mounted) {
      _showSnack('Google Sign-In failed or cancelled', isError: true);
    }
  }

  Future<void> _backupToDrive() async {
    final isSignedIn = ref.read(driveAuthProvider).isSignedIn;
    if (!isSignedIn) {
      _showSnack('Please sign in to Google first');
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final driveService = ref.read(driveServiceProvider);
    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Backup to Google Drive',
        operation: () =>
            ref.read(dataOperationProvider.notifier).uploadToDrive(db, driveService),
        onDone: (_) {
          ref.invalidate(driveBackupsProvider);
          _showSnack('✅ Backup uploaded to Google Drive');
        },
      ),
    );
  }

  Future<void> _restoreFromDrive(DriveBackupEntry entry) async {
    final db = ref.read(appDatabaseProvider);
    final driveService = ref.read(driveServiceProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cloud_download, color: Color(0xFF2196F3)),
          SizedBox(width: 10),
          Text('Restore from Drive'),
        ]),
        content: Text(
          'This will REPLACE all existing data with:\n\n${entry.name}\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    ref.read(dataOperationProvider.notifier).reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Restoring from Google Drive',
        operation: () => ref
            .read(dataOperationProvider.notifier)
            .downloadAndRestoreFromDrive(db, driveService, entry),
        onDone: (result) {
          if (result is RestoreResult) {
            _showSnack('✅ Restored ${result.products} products, ${result.customers} customers');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driveAuth = ref.watch(driveAuthProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // DRIVE SECTION
          _buildSectionHeader('Cloud Backup', Icons.cloud_outlined, const Color(0xFF2196F3)),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (driveAuth.isSignedIn)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: driveAuth.photoUrl != null
                            ? NetworkImage(driveAuth.photoUrl!)
                            : null,
                        child: driveAuth.photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(driveAuth.displayName ?? 'Google User',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(driveAuth.email ?? ''),
                      trailing: TextButton(
                        onPressed: () => ref.read(driveAuthProvider.notifier).signOut(),
                        child: const Text('Sign Out'),
                      ),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.cloud_off, color: Color(0xFF2196F3)),
                      ),
                      title: const Text('Not signed in',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Sign in to backup to Google Drive'),
                      trailing: FilledButton.tonal(
                        onPressed: _driveSignIn,
                        child: const Text('Sign In'),
                      ),
                    ),
                  const Divider(height: 32),
                  _ActionTile(
                    icon: Icons.backup_outlined,
                    title: 'Backup to Google Drive',
                    subtitle: 'Securely store a snapshot in the cloud',
                    color: const Color(0xFF2196F3),
                    onTap: driveAuth.isSignedIn ? _backupToDrive : null,
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.restore_page_outlined,
                    title: 'Restore from Google Drive',
                    subtitle: 'Recover your data from a cloud backup',
                    color: const Color(0xFF2196F3),
                    onTap: driveAuth.isSignedIn
                        ? () => DriveBackupListSheet.show(
                              context,
                              onRestoreSelected: _restoreFromDrive,
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // LOCAL SECTION
          _buildSectionHeader('Local Storage', Icons.sd_storage_outlined, const Color(0xFF3949AB)),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Location: $_localPath',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.save_alt,
                    title: 'Create Local Backup',
                    subtitle: 'Save a .hpbackup file to your device',
                    color: const Color(0xFF3949AB),
                    onTap: _createLocalBackup,
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.settings_backup_restore,
                    title: 'Restore Local Backup',
                    subtitle: 'Load data from a .hpbackup file',
                    color: const Color(0xFF3949AB),
                    onTap: _restoreFromLocal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isDisabled ? Colors.grey.shade200 : color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: isDisabled ? Colors.grey.shade50 : color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey.shade200 : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isDisabled ? Colors.grey : color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDisabled ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDisabled ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDisabled ? Colors.grey.shade300 : Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ManifestRow extends StatelessWidget {
  final String label;
  final String value;
  const _ManifestRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
