import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../transactions/models/transaction_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/business_profile_provider.dart';
import 'package:intl/intl.dart';

class PosReceiptScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;

  const PosReceiptScreen({
    super.key,
    required this.transaction,
    required this.items,
  });

  @override
  ConsumerState<PosReceiptScreen> createState() => _PosReceiptScreenState();
}

class _PosReceiptScreenState extends ConsumerState<PosReceiptScreen> {
  String _businessName = 'HamroByapar';
  String? _businessAddress;
  String? _businessPhone;
  String? _businessPan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final profile = await ref.read(businessProfileNotifierProvider.future);
      if (mounted) {
        setState(() {
          _businessName = profile.businessName.isNotEmpty ? profile.businessName : 'HamroByapar';
          _businessAddress = profile.address;
          _businessPhone = profile.phone;
          _businessPan = profile.panNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    final pdf = await _generatePdf(PdfPageFormat.roll80);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(pdf), 
      filename: 'receipt-${widget.transaction.invoiceNumber}.pdf'
    );
  }

  Future<void> _printPdf() async {
    final pdf = await _generatePdf(PdfPageFormat.roll80);
    await Printing.layoutPdf(
      onLayout: (format) async => Uint8List.fromList(pdf),
      name: 'receipt-${widget.transaction.invoiceNumber}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: _printPdf,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => Uint8List.fromList(await _generatePdf(format)),
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: PdfPageFormat.roll80,
        canChangePageFormat: true,
      ),
    );
  }

  Future<List<int>> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  _businessName.toUpperCase(), 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
                ),
              ),
              if (_businessAddress != null && _businessAddress!.isNotEmpty)
                pw.Center(child: pw.Text(_businessAddress!)),
              if (_businessPhone != null && _businessPhone!.isNotEmpty)
                pw.Center(child: pw.Text('Phone: $_businessPhone')),
              if (_businessPan != null && _businessPan!.isNotEmpty)
                pw.Center(child: pw.Text('PAN: $_businessPan')),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Invoice: ${widget.transaction.invoiceNumber}'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.transaction.transactionDate)}'),
              if (widget.transaction.customerName != null) 
                pw.Text('Customer: ${widget.transaction.customerName}'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Divider(),
              ...widget.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.productName),
                        if (item.selectedVariant != null) pw.Text('(${item.selectedVariant})', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    )),
                    pw.Expanded(child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text(CurrencyFormatter.format(item.totalPrice), textAlign: pw.TextAlign.right)),
                  ],
                ),
              )),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _buildSummaryRow('Subtotal', widget.transaction.amount),
              _buildSummaryRow('Tax (13%)', widget.transaction.vatAmount),
              pw.Divider(),
              _buildSummaryRow('TOTAL', widget.transaction.totalAmount, isBold: true),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for shopping!')),
              pw.Center(child: pw.Text('Please visit again.')),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(CurrencyFormatter.format(value), style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }
}