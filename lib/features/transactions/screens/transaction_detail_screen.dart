import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/services/thermal_printer_service.dart';
import '../../../core/providers/business_profile_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionByIdProvider(transactionId));

    return Scaffold(
      backgroundColor: const Color(0xFFDEE6F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.print),
            onSelected: (value) {
              if (value == 'pdf') {
                _printInvoice(context, ref);
              } else if (value == 'thermal') {
                _printThermalReceipt(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Print PDF (A4)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'thermal',
                child: Row(
                  children: [
                    Icon(Icons.receipt),
                    SizedBox(width: 8),
                    Text('Print Receipt (Thermal)'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTransaction(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text('Transaction not found'));
          }
          return _buildContent(context, transaction);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransactionModel transaction) {
    final typeColor = _getTypeColor(transaction.type);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(transaction.type),
                    size: 40,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  transaction.invoiceNumber,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    transaction.type.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  'Amount',
                  CurrencyFormatter.format(transaction.amount),
                ),
                if (transaction.vatAmount > 0) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'VAT (13%)',
                    CurrencyFormatter.format(transaction.vatAmount),
                  ),
                ],
                const Divider(height: 24),
                _buildDetailRow(
                  context,
                  'Total Amount',
                  CurrencyFormatter.format(transaction.totalAmount),
                  isBold: true,
                  valueColor: typeColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                if (transaction.customerName != null) ...[
                  _buildInfoRow(
                    context,
                    Icons.person,
                    'Customer',
                    transaction.customerName!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (transaction.customerAddress != null && transaction.customerAddress!.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    Icons.location_on,
                    'Address',
                    transaction.customerAddress!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (transaction.customerPhone != null && transaction.customerPhone!.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    Icons.phone,
                    'Contact',
                    transaction.customerPhone!,
                  ),
                  const SizedBox(height: 12),
                ],
                if (transaction.customerPan != null && transaction.customerPan!.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    Icons.badge,
                    'PAN/VAT ID',
                    transaction.customerPan!,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildInfoRow(
                  context,
                  Icons.calendar_today,
                  'Date',
                  DateFormatter.formatBS(transaction.transactionDate),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.payment,
                  'Payment Method',
                  transaction.paymentMethod,
                ),
                if (transaction.notes != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.note,
                    'Notes',
                    transaction.notes!,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (transaction.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildItemsCard(context, transaction),
        ],
        if (transaction.attachments != null &&
            transaction.attachments!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAttachmentsCard(context, transaction),
        ],
      ],
    );
  }

  Widget _buildItemsCard(BuildContext context, TransactionModel transaction) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...transaction.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.totalPrice),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(
      BuildContext context, TransactionModel transaction,) {
    final paths = transaction.attachments!.split(',');
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: paths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filePath = paths[index].trim();
                  final isImage = ['.jpg', '.jpeg', '.png', '.gif']
                      .any((ext) => filePath.toLowerCase().endsWith(ext));
                  final file = File(filePath);

                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isImage && file.existsSync()
                          ? Image.file(file, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf,
                                    color: Colors.red, size: 36,),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4,),
                                  child: Text(
                                    filePath.split('/').last,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _shareInvoice(BuildContext context, WidgetRef ref) async {
    final transactionAsync = await ref.read(transactionByIdProvider(transactionId).future);
    
    if (transactionAsync == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction not found')),
      );
      return;
    }

    try {
      // Show loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get business profile
      final businessProfile = await ref.read(businessProfileNotifierProvider.future);

      // Generate PDF
      final pdfFile = await _generatePdfInvoice(
        transactionAsync,
        businessName: businessProfile.businessName.isNotEmpty ? businessProfile.businessName : null,
        businessAddress: businessProfile.address,
        businessPan: businessProfile.panNumber,
        businessPhone: businessProfile.phone,
      );

      // Close loading
      if (!context.mounted) return;
      Navigator.pop(context);

      // Share PDF
      await PdfInvoiceService.shareInvoice(pdfFile);
    } catch (e) {
      // Close loading if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printInvoice(BuildContext context, WidgetRef ref) async {
    final transactionAsync = await ref.read(transactionByIdProvider(transactionId).future);
    
    if (transactionAsync == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction not found')),
      );
      return;
    }

    try {
      // Show loading
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get business profile
      final businessProfile = await ref.read(businessProfileNotifierProvider.future);

      // Generate PDF
      final pdfFile = await _generatePdfInvoice(
        transactionAsync,
        businessName: businessProfile.businessName.isNotEmpty ? businessProfile.businessName : null,
        businessAddress: businessProfile.address,
        businessPan: businessProfile.panNumber,
        businessPhone: businessProfile.phone,
      );

      // Close loading
      if (!context.mounted) return;
      Navigator.pop(context);

      // Print PDF
      await PdfInvoiceService.printInvoice(pdfFile);
    } catch (e) {
      // Close loading if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printThermalReceipt(BuildContext context, WidgetRef ref) async {
    final transactionAsync = await ref.read(transactionByIdProvider(transactionId).future);
    
    if (transactionAsync == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction not found')),
      );
      return;
    }

    try {
      // Get business profile
      final businessProfile = await ref.read(businessProfileNotifierProvider.future);

      // Convert transaction items to receipt items
      final receiptItems = transactionAsync.items.map((item) {
        return ReceiptItem(
          name: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          total: item.totalPrice,
        );
      }).toList();

      // Generate thermal receipt bytes
      final receiptBytes = ThermalPrinterService.generateReceipt(
        businessName: businessProfile.businessName.isNotEmpty ? businessProfile.businessName : 'HamroByapar',
        businessAddress: businessProfile.address,
        businessPhone: businessProfile.phone,
        businessPan: businessProfile.panNumber,
        invoiceNumber: transactionAsync.invoiceNumber,
        invoiceDate: transactionAsync.transactionDate,
        customerName: transactionAsync.customerName ?? 'Walk-in Customer',
        items: receiptItems,
        subtotal: transactionAsync.amount,
        vatAmount: transactionAsync.vatAmount,
        total: transactionAsync.totalAmount,
        notes: transactionAsync.notes,
        paymentMethod: transactionAsync.paymentMethod,
      );

      // Try to print
      await ThermalPrinterService.printReceipt(receiptBytes);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt sent to printer'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      // Show dialog with thermal printing info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thermal Printer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thermal printing requires a Bluetooth thermal printer.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('To use thermal printing:'),
              const SizedBox(height: 8),
              const Text('1. Connect a Bluetooth thermal printer'),
              const Text('2. Pair it with your device'),
              const Text('3. Try printing again'),
              const SizedBox(height: 16),
              Text(
                'For now, you can use PDF printing instead.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _printInvoice(context, ref);
              },
              child: const Text('Print PDF'),
            ),
          ],
        ),
      );
    }
  }

  Future<File> _generatePdfInvoice(TransactionModel transaction, {String? businessName, String? businessAddress, String? businessPan, String? businessPhone}) async {
    // Convert transaction items to invoice items
    final invoiceItems = transaction.items.map((item) {
      return InvoiceItem(
        name: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        total: item.totalPrice,
      );
    }).toList();

    // Generate PDF
    return await PdfInvoiceService.generateInvoice(
      invoiceNumber: transaction.invoiceNumber,
      invoiceDate: transaction.transactionDate,
      customerName: transaction.customerName ?? 'Walk-in Customer',
      customerAddress: transaction.customerAddress,
      customerPan: transaction.customerPan,
      customerPhone: transaction.customerPhone,
      items: invoiceItems,
      subtotal: transaction.amount,
      vatAmount: transaction.vatAmount,
      total: transaction.totalAmount,
      notes: transaction.notes,
      businessName: businessName ?? 'HamroByapar',
      businessAddress: businessAddress,
      businessPan: businessPan,
      businessPhone: businessPhone,
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.green;
      case 'purchase':
        return Colors.blue;
      case 'expense':
        return Colors.red;
      case 'payment':
        return Colors.orange;
      case 'receipt':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sale':
        return Icons.shopping_cart;
      case 'purchase':
        return Icons.shopping_bag;
      case 'expense':
        return Icons.money_off;
      case 'payment':
        return Icons.payment;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.receipt_long;
    }
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(transactionActionsProvider.notifier).deleteTransaction(transactionId);
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
