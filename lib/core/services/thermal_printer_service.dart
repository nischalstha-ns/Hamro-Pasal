import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class ThermalPrinterService {
  // ESC/POS Commands
  // ignore: constant_identifier_names
  static const ESC = 0x1B;
  // ignore: constant_identifier_names
  static const GS = 0x1D;
  
  // Text alignment
  // ignore: constant_identifier_names
  static const ALIGN_LEFT = [ESC, 0x61, 0x00];
  // ignore: constant_identifier_names
  static const ALIGN_CENTER = [ESC, 0x61, 0x01];
  // ignore: constant_identifier_names
  static const ALIGN_RIGHT = [ESC, 0x61, 0x02];
  
  // Text size
  // ignore: constant_identifier_names
  static const TEXT_NORMAL = [ESC, 0x21, 0x00];
  // ignore: constant_identifier_names
  static const TEXT_DOUBLE_HEIGHT = [ESC, 0x21, 0x10];
  // ignore: constant_identifier_names
  static const TEXT_DOUBLE_WIDTH = [ESC, 0x21, 0x20];
  // ignore: constant_identifier_names
  static const TEXT_DOUBLE = [ESC, 0x21, 0x30];
  
  // Text style
  // ignore: constant_identifier_names
  static const TEXT_BOLD_ON = [ESC, 0x45, 0x01];
  // ignore: constant_identifier_names
  static const TEXT_BOLD_OFF = [ESC, 0x45, 0x00];
  // ignore: constant_identifier_names
  static const TEXT_UNDERLINE_ON = [ESC, 0x2D, 0x01];
  // ignore: constant_identifier_names
  static const TEXT_UNDERLINE_OFF = [ESC, 0x2D, 0x00];
  
  // Line feed
  // ignore: constant_identifier_names
  static const LINE_FEED = [0x0A];
  // ignore: constant_identifier_names
  static const PAPER_CUT = [GS, 0x56, 0x00];
  
  /// Generate thermal receipt bytes for printing
  static List<int> generateReceipt({
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessPan,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String customerName,
    required List<ReceiptItem> items,
    required double subtotal,
    required double vatAmount,
    required double total,
    String? notes,
    String paymentMethod = 'Cash',
  }) {
    final List<int> bytes = [];
    
    // Initialize printer
    bytes.addAll([ESC, 0x40]); // Initialize
    
    // Header - Business Name (Large, Bold, Center)
    bytes.addAll(ALIGN_CENTER);
    bytes.addAll(TEXT_DOUBLE);
    bytes.addAll(TEXT_BOLD_ON);
    bytes.addAll(_encodeText(businessName));
    bytes.addAll(LINE_FEED);
    bytes.addAll(TEXT_NORMAL);
    bytes.addAll(TEXT_BOLD_OFF);
    
    // Business Details (Center)
    if (businessAddress != null) {
      bytes.addAll(_encodeText(businessAddress));
      bytes.addAll(LINE_FEED);
    }
    if (businessPhone != null) {
      bytes.addAll(_encodeText('Tel: $businessPhone'));
      bytes.addAll(LINE_FEED);
    }
    if (businessPan != null) {
      bytes.addAll(_encodeText('PAN: $businessPan'));
      bytes.addAll(LINE_FEED);
    }
    
    // Separator
    bytes.addAll(LINE_FEED);
    bytes.addAll(_encodeText(_repeatChar('-', 32)));
    bytes.addAll(LINE_FEED);
    
    // Invoice Info (Left aligned)
    bytes.addAll(ALIGN_LEFT);
    bytes.addAll(_encodeText('Invoice: $invoiceNumber'));
    bytes.addAll(LINE_FEED);
    bytes.addAll(_encodeText('Date: ${DateFormatter.formatBS(invoiceDate)}'));
    bytes.addAll(LINE_FEED);
    bytes.addAll(_encodeText('Customer: $customerName'));
    bytes.addAll(LINE_FEED);
    
    // Separator
    bytes.addAll(_encodeText(_repeatChar('-', 32)));
    bytes.addAll(LINE_FEED);
    
    // Items Header
    bytes.addAll(TEXT_BOLD_ON);
    bytes.addAll(_encodeText(_formatLine('Item', 'Qty', 'Amount')));
    bytes.addAll(LINE_FEED);
    bytes.addAll(TEXT_BOLD_OFF);
    bytes.addAll(_encodeText(_repeatChar('-', 32)));
    bytes.addAll(LINE_FEED);
    
    // Items
    for (final item in items) {
      // Item name
      bytes.addAll(_encodeText(item.name));
      bytes.addAll(LINE_FEED);
      
      // Quantity x Rate = Amount
      final qtyRate = '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}';
      final amount = item.total.toStringAsFixed(2);
      bytes.addAll(_encodeText(_formatLine('', qtyRate, amount)));
      bytes.addAll(LINE_FEED);
    }
    
    // Separator
    bytes.addAll(_encodeText(_repeatChar('-', 32)));
    bytes.addAll(LINE_FEED);
    
    // Totals (Right aligned)
    bytes.addAll(ALIGN_RIGHT);
    bytes.addAll(_encodeText('Subtotal: ${CurrencyFormatter.format(subtotal)}'));
    bytes.addAll(LINE_FEED);
    
    if (vatAmount > 0) {
      bytes.addAll(_encodeText('VAT (13%): ${CurrencyFormatter.format(vatAmount)}'));
      bytes.addAll(LINE_FEED);
    }
    
    bytes.addAll(TEXT_BOLD_ON);
    bytes.addAll(TEXT_DOUBLE_HEIGHT);
    bytes.addAll(_encodeText('Total: ${CurrencyFormatter.format(total)}'));
    bytes.addAll(LINE_FEED);
    bytes.addAll(TEXT_NORMAL);
    bytes.addAll(TEXT_BOLD_OFF);
    
    // Payment Method
    bytes.addAll(ALIGN_LEFT);
    bytes.addAll(_encodeText('Payment: $paymentMethod'));
    bytes.addAll(LINE_FEED);
    
    // Notes
    if (notes != null && notes.isNotEmpty) {
      bytes.addAll(LINE_FEED);
      bytes.addAll(_encodeText('Notes: $notes'));
      bytes.addAll(LINE_FEED);
    }
    
    // Footer
    bytes.addAll(LINE_FEED);
    bytes.addAll(ALIGN_CENTER);
    bytes.addAll(_encodeText(_repeatChar('-', 32)));
    bytes.addAll(LINE_FEED);
    bytes.addAll(_encodeText('Thank you for your business!'));
    bytes.addAll(LINE_FEED);
    bytes.addAll(_encodeText('Digital Khata'));
    bytes.addAll(LINE_FEED);
    bytes.addAll(LINE_FEED);
    bytes.addAll(LINE_FEED);
    
    // Cut paper
    bytes.addAll(PAPER_CUT);
    
    return bytes;
  }
  
  /// Encode text to bytes (ASCII)
  static List<int> _encodeText(String text) {
    return text.codeUnits;
  }
  
  /// Repeat character n times
  static String _repeatChar(String char, int count) {
    return char * count;
  }
  
  /// Format line with 3 columns
  static String _formatLine(String col1, String col2, String col3) {
    const col1Width = 10;
    const col2Width = 10;
    const col3Width = 12;
    
    final c1 = col1.padRight(col1Width).substring(0, col1Width);
    final c2 = col2.padRight(col2Width).substring(0, col2Width);
    final c3 = col3.padLeft(col3Width).substring(0, col3Width);
    
    return '$c1$c2$c3';
  }
  
  /// Print receipt to thermal printer
  /// Note: This requires bluetooth_print package or similar
  /// For now, this is a placeholder that shows how to use the bytes
  static Future<void> printReceipt(List<int> bytes) async {
    // TODO: Implement actual printing using bluetooth_print or similar package
    // Example:
    // final printer = BluetoothPrint.instance;
    // await printer.printReceipt(bytes);
    
    throw UnimplementedError(
      'Thermal printing requires bluetooth_print package. '
      'Please connect a Bluetooth thermal printer and implement the printing logic.',
    );
  }
  
  /// Get list of available Bluetooth printers
  static Future<List<BluetoothDevice>> getAvailablePrinters() async {
    // TODO: Implement using bluetooth_print package
    // Example:
    // final printer = BluetoothPrint.instance;
    // return await printer.getBondedDevices();
    
    return [];
  }
  
  /// Connect to a Bluetooth printer
  static Future<bool> connectToPrinter(BluetoothDevice device) async {
    // TODO: Implement using bluetooth_print package
    // Example:
    // final printer = BluetoothPrint.instance;
    // await printer.connect(device);
    // return printer.isConnected;
    
    return false;
  }
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;
  
  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class BluetoothDevice {
  final String name;
  final String address;
  
  BluetoothDevice({
    required this.name,
    required this.address,
  });
}
