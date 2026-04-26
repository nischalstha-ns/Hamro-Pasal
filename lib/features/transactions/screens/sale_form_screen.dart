import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_date_picker.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../customers/providers/customers_provider.dart';
import 'package:nepali_utils/nepali_utils.dart';

class SaleFormScreen extends ConsumerStatefulWidget {
  const SaleFormScreen({super.key});

  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _panVatController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _discountController = TextEditingController();
  final _receivedController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isCreditSale = false;
  int _invoiceNumber = 1;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Cash';
  bool _discountIsPercentage = true;
  double _vatRate = 0.13;
  bool _isLoading = false;

  final List<SaleItem> _items = [];
  final List<PlatformFile> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadNextInvoiceNumber();
  }

  Future<void> _loadNextInvoiceNumber() async {
    try {
      final transactions = await ref.read(transactionsStreamProvider.future);
      final saleTransactions = transactions.where((t) => t.type == 'sale').toList();
      setState(() => _invoiceNumber = saleTransactions.length + 1);
    } catch (e) {
      setState(() => _invoiceNumber = 1);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerContactController.dispose();
    _panVatController.dispose();
    _customerAddressController.dispose();
    _discountController.dispose();
    _receivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculateItemsSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _calculateDiscount() {
    final subtotal = _calculateItemsSubtotal();
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (_discountIsPercentage) {
      return subtotal * (discountValue / 100);
    }
    return discountValue;
  }

  double _calculateTax() {
    final subtotal = _calculateItemsSubtotal();
    final discount = _calculateDiscount();
    return (subtotal - discount) * _vatRate;
  }

  double _calculateTotal() {
    final subtotal = _calculateItemsSubtotal();
    final discount = _calculateDiscount();
    final tax = _calculateTax();
    return subtotal - discount + tax;
  }

  double _calculateBalanceDue() {
    final total = _calculateTotal();
    final received = double.tryParse(_receivedController.text) ?? 0;
    return total - received;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Sales'),
        actions: [
          _buildCreditCashToggle(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInvoiceAndDate(),
            const SizedBox(height: 16),
            _buildCustomerField(),
            const SizedBox(height: 16),
            _buildBilledItems(),
            const SizedBox(height: 16),
            _buildTaxAndDiscount(),
            const SizedBox(height: 16),
            _buildTotalAmount(),
            const SizedBox(height: 16),
            _buildReceivedAmount(),
            const SizedBox(height: 8),
            _buildBalanceDue(),
            const SizedBox(height: 16),
            _buildPaymentType(),
            const SizedBox(height: 16),
            _buildDescription(),
            const SizedBox(height: 16),
            _buildAddDocument(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCashToggle() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildToggleButton('Credit', true),
          _buildToggleButton('Cash', false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isCredit) {
    final isSelected = _isCreditSale == isCredit;
    return GestureDetector(
      onTap: () => setState(() => _isCreditSale = isCredit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D9E75) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceAndDate() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice No.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _invoiceNumber.toString().padLeft(3, '0'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDateBS(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer *',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            hintText: 'Enter customer name',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        Text(
          'Contact Number',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _customerContactController,
          decoration: const InputDecoration(
            hintText: 'Enter contact number',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Text(
          'Address',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _customerAddressController,
          decoration: const InputDecoration(
            hintText: 'Enter customer address',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Text(
          'PAN / VAT ID',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _panVatController,
          decoration: const InputDecoration(
            hintText: 'Enter PAN / VAT number',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildBilledItems() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Billed Items',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
          ),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No items added',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(item, index);
            }),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Disc: ${_calculateDiscount().toStringAsFixed(1)}'),
                    Text('Total Tax Amt: ${_calculateTax().toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Qty: ${_items.fold(0.0, (sum, item) => sum + item.quantity)}'),
                    Text('Subtotal: ${_calculateItemsSubtotal().toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _showAddItemDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Add Items',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(SaleItem item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${index + 1}  ${item.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.format(item.price * item.quantity),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _items.removeAt(index)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Item Subtotal    ${item.quantity} Pcs x ${item.price.toStringAsFixed(2)} = ${(item.price * item.quantity).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxAndDiscount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tax & Discount',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 80, child: Text('Discount')),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _discountIsPercentage = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: _discountIsPercentage ? Colors.amber : Colors.transparent,
                            child: const Text('%'),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _discountIsPercentage = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: !_discountIsPercentage ? Colors.amber : Colors.transparent,
                            child: const Text('Rs'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _calculateDiscount().toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 80, child: Text('Tax')),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      initialValue: _vatRate,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0.13, child: Text('VAT 13%')),
                        DropdownMenuItem(value: 0.0, child: Text('No Tax')),
                      ],
                      onChanged: (value) => setState(() => _vatRate = value ?? 0.13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Rs'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _calculateTax().toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            'Rs ${_calculateTotal().toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedAmount() {
    return Row(
      children: [
        Checkbox(
          value: _receivedController.text.isNotEmpty,
          onChanged: (value) {
            if (value == true) {
              _receivedController.text = _calculateTotal().toStringAsFixed(2);
            } else {
              _receivedController.text = '';
            }
            setState(() {});
          },
        ),
        const Text('Received'),
        const Spacer(),
        const Text('Rs'),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: _receivedController,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDue() {
    final balance = _calculateBalanceDue();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Balance Due',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1D9E75),
            ),
          ),
          Text(
            'Rs ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1D9E75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '\$',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  underline: const SizedBox(),
                  items: ['Cash', 'eSewa', 'Khalti', 'fonepay', 'Bank Transfer']
                      .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Payment Type'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Add Note',
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachedFiles.addAll(result.files);
      });
    }
  }

  Widget _buildAddDocument() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachedFiles.isNotEmpty) ...
          [
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedFiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final file = _attachedFiles[index];
                  final isImage = ['jpg', 'jpeg', 'png', 'gif']
                      .contains(file.extension?.toLowerCase());
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isImage && file.path != null
                              ? Image.file(
                                  File(file.path!),
                                  fit: BoxFit.cover,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf,
                                        color: Colors.red, size: 32,),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4,),
                                      child: Text(
                                        file.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _attachedFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14,),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Colors.grey[400], size: 32,),
                  const SizedBox(height: 8),
                  Text(
                    _attachedFiles.isEmpty ? 'Add Document' : 'Add More',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports images (JPG, PNG) and PDF',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _saveAndNew,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save & New'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  String _formatDateBS(DateTime date) {
    final nepaliDate = date.toNepaliDateTime();
    final months = [
      'Baisakh',
      'Jestha',
      'Ashadh',
      'Shrawan',
      'Bhadra',
      'Ashwin',
      'Kartik',
      'Mangsir',
      'Poush',
      'Magh',
      'Falgun',
      'Chaitra',
    ];
    return '${nepaliDate.day}-${months[nepaliDate.month - 1]}-${nepaliDate.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: _selectedDate,
      isBikramSambat: true,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() => _items.add(item));
        },
      ),
    );
  }

  Future<List<String>> _saveFilesToUploadFolder() async {
    final savedPaths = <String>[];
    if (_attachedFiles.isEmpty) return savedPaths;

    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory(p.join(appDir.path, 'upload'));
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    for (final file in _attachedFiles) {
      if (file.path != null) {
        final sourceFile = File(file.path!);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destPath = p.join(uploadDir.path, '${timestamp}_${file.name}');
        await sourceFile.copy(destPath);
        savedPaths.add(destPath);
      }
    }
    return savedPaths;
  }

  Future<void> _saveTransaction() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Look up customer ID by name if provided
      int? customerId;
      final customerName = _customerNameController.text.trim();
      if (customerName.isNotEmpty) {
        final customersAsync = await ref.read(customersStreamProvider.future);
        final match = customersAsync
            .where((c) => c.name.toLowerCase() == customerName.toLowerCase())
            .toList();
        if (match.isNotEmpty) {
          customerId = match.first.id;
        }
      }

      // Save attached files to upload folder
      final savedPaths = await _saveFilesToUploadFolder();
      final attachmentsStr = savedPaths.isNotEmpty ? savedPaths.join(',') : null;

      final transaction = TransactionModel(
        id: 0,
        invoiceNumber: 'INV-${_invoiceNumber.toString().padLeft(3, '0')}',
        type: 'sale',
        customerId: customerId,
        customerName: customerName.isEmpty ? null : customerName,
        customerPhone: _customerContactController.text.trim().isEmpty ? null : _customerContactController.text.trim(),
        customerAddress: _customerAddressController.text.trim().isEmpty ? null : _customerAddressController.text.trim(),
        customerPan: _panVatController.text.trim().isEmpty ? null : _panVatController.text.trim(),
        amount: _calculateItemsSubtotal(),
        vatAmount: _calculateTax(),
        totalAmount: _calculateTotal(),
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        attachments: attachmentsStr,
        transactionDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      final txnItems = _items
          .map((item) => TransactionItemModel(
                id: 0,
                transactionId: 0,
                productId: item.productId,
                productName: item.name,
                quantity: item.quantity.toInt(),
                unitPrice: item.price,
                totalPrice: item.price * item.quantity,
              ),)
          .toList();

      await ref.read(transactionActionsProvider.notifier).addTransactionWithItems(
            transaction: transaction,
            items: txnItems,
          );

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sale saved successfully${customerName.isNotEmpty ? " for $customerName" : ""}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveAndNew() async {
    await _saveTransaction();
    if (mounted) {
      setState(() {
        _items.clear();
        _customerNameController.clear();
        _customerContactController.clear();
        _customerAddressController.clear();
        _panVatController.clear();
        _discountController.clear();
        _receivedController.clear();
        _notesController.clear();
        _attachedFiles.clear();
      });
      await _loadNextInvoiceNumber();
    }
  }
}

class SaleItem {
  final int productId;
  final String name;
  final double price;
  final double quantity;

  SaleItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class _AddItemDialog extends ConsumerStatefulWidget {
  final Function(SaleItem) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  ConsumerState<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<_AddItemDialog> {
  final _quantityController = TextEditingController(text: '1');
  int? _selectedProductId;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return AlertDialog(
      title: const Text('Add Item'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            productsAsync.when(
              data: (products) => DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Select Product',
                  border: OutlineInputBorder(),
                ),
                items: products.map((product) {
                  return DropdownMenuItem(
                    value: product.id,
                    child: Text('${product.name} - Rs ${product.price}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                  });
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading products'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_selectedProductId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a product')),
              );
              return;
            }

            final productsAsync = ref.read(productsStreamProvider);
            productsAsync.whenData((products) {
              final product = products.firstWhere((p) => p.id == _selectedProductId);
              final quantity = double.tryParse(_quantityController.text) ?? 1;

              widget.onAdd(
                SaleItem(
                  productId: product.id,
                  name: product.name,
                  price: product.price,
                  quantity: quantity,
                ),
              );

              Navigator.pop(context);
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
