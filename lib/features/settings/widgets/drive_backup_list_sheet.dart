import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/drive_service.dart';
import '../providers/data_management_provider.dart';

/// Bottom sheet listing available Google Drive backups with restore action.
class DriveBackupListSheet extends ConsumerWidget {
  const DriveBackupListSheet({super.key, this.onRestoreSelected});

  final void Function(DriveBackupEntry entry)? onRestoreSelected;

  static Future<void> show(
    BuildContext context, {
    void Function(DriveBackupEntry entry)? onRestoreSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DriveBackupListSheet(onRestoreSelected: onRestoreSelected),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(driveBackupsProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: Color(0xFF2196F3)),
                const SizedBox(width: 10),
                Text(
                  'Drive Backups',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(driveBackupsProvider),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: backupsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('Failed to load backups', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(e.toString(),
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(driveBackupsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (backups) {
                  if (backups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_queue, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'No backups found',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a backup first using\n"Backup to Google Drive"',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: backups.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final entry = backups[i];
                      final sizeKb = (entry.sizeBytes / 1024).toStringAsFixed(1);
                      final date = _formatDate(entry.createdTime);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_zip_outlined,
                              color: Color(0xFF2196F3)),
                        ),
                        title: Text(
                          entry.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('$date  •  $sizeKb KB',
                            style: const TextStyle(fontSize: 11)),
                        trailing: FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(context);
                            onRestoreSelected?.call(entry);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Restore'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
