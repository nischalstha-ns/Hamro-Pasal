import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_management_provider.dart';

/// A full-screen modal dialog showing live operation progress with logs.
class ProgressDialog extends ConsumerStatefulWidget {
  const ProgressDialog({
    super.key,
    required this.title,
    required this.operation,
    this.onDone,
  });

  final String title;
  final Future<void> Function() operation;
  final void Function(Object? result)? onDone;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required WidgetRef ref,
    required Future<void> Function() operation,
    void Function(Object? result)? onDone,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(title: title, operation: operation, onDone: onDone),
    );
  }

  @override
  ConsumerState<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends ConsumerState<ProgressDialog> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.operation());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataOperationProvider);
    final isDone = state.status == OperationStatus.done;
    final isError = state.status == OperationStatus.error;
    final isRunning = state.status == OperationStatus.running;

    // Auto-scroll logs to bottom
    if (state.logs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Notify caller on done
    if (isDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDone?.call(state.resultData);
      });
    }

    final statusColor = isError
        ? Colors.red
        : isDone
            ? Colors.green
            : const Color(0xFFE21B22);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isRunning
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: statusColor,
                            ),
                          )
                        : Icon(
                            isError ? Icons.error_outline : Icons.check_circle_outline,
                            color: statusColor,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: isRunning ? state.progress : (isDone ? 1.0 : null),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isError
                    ? 'Failed: ${state.error}'
                    : isDone
                        ? 'Completed successfully!'
                        : state.currentStep,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isError ? Colors.red : Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 16),

              // Log panel
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: state.logs.isEmpty
                      ? Center(
                          child: Text(
                            'Starting…',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: state.logs.length,
                          itemBuilder: (_, i) {
                            final isLast = i == state.logs.length - 1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isLast && isRunning
                                        ? Icons.arrow_right
                                        : Icons.check,
                                    size: 14,
                                    color: isLast && isRunning
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      state.logs[i],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: isLast && isRunning
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (isDone || isError)
                      ? () => Navigator.of(context).pop()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isError ? 'Close' : 'Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
