import 'package:flutter/material.dart';
import '../../../core/services/data_import_service.dart';

/// Bottom sheet that shows a parsed import preview before committing.
class ImportPreviewSheet extends StatelessWidget {
  const ImportPreviewSheet({super.key, required this.preview});

  final ImportPreview preview;

  static Future<bool?> show(BuildContext context, ImportPreview preview) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ImportPreviewSheet(preview: preview),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasErrors = preview.errors.isNotEmpty;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  const Icon(Icons.table_chart_outlined, color: Color(0xFFFF9800)),
                  const SizedBox(width: 10),
                  Text(
                    'Import Preview',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats chips
              Wrap(
                spacing: 8,
                children: [
                  _Chip(
                    label: '${preview.totalRows} rows',
                    color: Colors.blue,
                    icon: Icons.table_rows,
                  ),
                  _Chip(
                    label: '${preview.validRows} valid',
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                  ),
                  if (hasErrors)
                    _Chip(
                      label: '${preview.errors.length} errors',
                      color: Colors.red,
                      icon: Icons.warning_amber_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Column mapping
              Text('Detected Columns', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: preview.columns.map((col) {
                  return Chip(
                    label: Text(col, style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Data preview
              Text('Data Preview (first ${preview.previewRows.length} rows)',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
                        columns: preview.columns
                            .take(6)
                            .map((c) => DataColumn(
                                  label: Text(c,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 12)),
                                ))
                            .toList(),
                        rows: preview.previewRows.map((row) {
                          return DataRow(
                            cells: row
                                .take(6)
                                .map((cell) => DataCell(
                                      Text(
                                        cell.length > 20
                                            ? '${cell.substring(0, 20)}…'
                                            : cell,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ))
                                .toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),

              // Errors
              if (hasErrors) ...[
                const SizedBox(height: 12),
                Text('Validation Errors', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: preview.errors
                        .map((e) => Text('• $e',
                            style: const TextStyle(fontSize: 11, color: Colors.red)))
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: preview.validRows > 0
                          ? () => Navigator.pop(context, true)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                      ),
                      icon: const Icon(Icons.download_done),
                      label: Text('Import ${preview.validRows} rows'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
