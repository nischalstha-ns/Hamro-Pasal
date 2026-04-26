import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class PdfInvoiceService {
  static Future<File> generateInvoice({
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String customerName,
    String? customerAddress,
    String? customerPan,
    String? customerPhone,
    required List<InvoiceItem> items,
    required double subtotal,
    required double vatAmount,
    required double total,
    String? notes,
    String businessName = 'HamroByapar',
    String? businessAddress,
    String? businessPan,
    String? businessPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Business Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1D9E75'),
                        ),
                      ),
                      if (businessAddress != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(businessAddress, style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (businessPhone != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Phone: $businessPhone', style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (businessPan != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('PAN: $businessPan', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '#$invoiceNumber',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Invoice Date and Customer Details Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Date Section
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DATE',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          DateFormatter.formatBS(invoiceDate),
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          DateFormatter.formatAD(invoiceDate),
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Customer Details Section
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F5F5F5'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILL TO',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            customerName,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Phone: ${customerPhone ?? '-'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Address: ${customerAddress ?? '-'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'PAN/VAT: ${customerPan ?? '-'}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // Items Table
              _buildItemsTable(items),
              pw.SizedBox(height: 20),

              // Totals Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _buildTotalRow('Subtotal:', subtotal),
                        pw.SizedBox(height: 6),
                        _buildTotalRow('VAT (13%):', vatAmount),
                        pw.SizedBox(height: 8),
                        pw.Divider(),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#1D9E75'),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'TOTAL',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                CurrencyFormatter.format(total),
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (notes != null && notes.isNotEmpty) ...[
                pw.SizedBox(height: 25),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F9F9F9'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        notes,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Generated by HamroByapar - हाम्रो ब्यापार',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }



  static pw.Widget _buildItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1D9E75')),
          children: [
            _buildTableCell('ITEM', isHeader: true, isHeaderRow: true),
            _buildTableCell('QTY', isHeader: true, align: pw.TextAlign.center, isHeaderRow: true),
            _buildTableCell('RATE', isHeader: true, align: pw.TextAlign.right, isHeaderRow: true),
            _buildTableCell('AMOUNT', isHeader: true, align: pw.TextAlign.right, isHeaderRow: true),
          ],
        ),
        // Items
        ...items.asMap().entries.map(
          (entry) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: entry.key % 2 == 0 ? PdfColors.white : PdfColor.fromHex('#F9F9F9'),
            ),
            children: [
              _buildTableCell(entry.value.name),
              _buildTableCell(
                entry.value.quantity.toString(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                CurrencyFormatter.format(entry.value.unitPrice),
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                CurrencyFormatter.format(entry.value.total),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isHeaderRow = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeaderRow ? PdfColors.white : PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 11,
          ),
        ),
        pw.Text(
          CurrencyFormatter.format(amount),
          style: const pw.TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  static Future<void> printInvoice(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  static Future<void> shareInvoice(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }
}

class InvoiceItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}
