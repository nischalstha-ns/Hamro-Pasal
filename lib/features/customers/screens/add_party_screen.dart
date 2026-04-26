import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/custom_date_picker.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/customers_provider.dart';

class AddPartyScreen extends ConsumerStatefulWidget {
  const AddPartyScreen({super.key});

  @override
  ConsumerState<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends ConsumerState<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _emailController = TextEditingController();
  final _panVatController = TextEditingController();

  DateTime _asOfDate = DateTime.now();
  bool _isToReceive = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _openingBalanceController.dispose();
    _billingAddressController.dispose();
    _emailController.dispose();
    _panVatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Party'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPartyNameField(),
                  const SizedBox(height: 8),
                  _buildAddThroughContacts(),
                  const SizedBox(height: 16),
                  _buildContactNumberField(),
                  const SizedBox(height: 16),
                  _buildOpeningBalanceAndDate(),
                  const SizedBox(height: 16),
                  _buildBalanceTypeRadios(),
                  const SizedBox(height: 24),
                  _buildCreditLimitButton(),
                  const SizedBox(height: 24),
                  _buildAddressesSection(),
                  const SizedBox(height: 16),
                  _buildBillingAddressField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPanVatField(),
                  const SizedBox(height: 24),
                  _buildInfoText(),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Party Name*',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter party name',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Party name is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddThroughContacts() {
    return TextButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact picker coming soon')),
        );
      },
      icon: const Icon(Icons.contacts),
      label: const Text('Add party through contacts'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildContactNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Number',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            hintText: 'Enter contact number',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildOpeningBalanceAndDate() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Opening Bal.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _openingBalanceController,
                decoration: const InputDecoration(
                  hintText: '0',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'As of Date',
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                  ),
                  child: Text(DateFormatter.formatBS(_asOfDate)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceTypeRadios() {
    return RadioGroup<bool>(
      groupValue: _isToReceive,
      onChanged: (v) => setState(() => _isToReceive = v ?? false),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<bool>(
              value: false,
              title: const Text('To Receive'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              value: true,
              title: const Text('To Pay'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditLimitButton() {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit limit feature coming soon')),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Set Credit Limit'),
          const SizedBox(width: 8),
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      child: const Text(
        'Addresses',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBillingAddressField() {
    return TextFormField(
      controller: _billingAddressController,
      decoration: InputDecoration(
        hintText: 'Billing Address',
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'example@email.com',
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPanVatField() {
    return TextFormField(
      controller: _panVatController,
      decoration: InputDecoration(
        labelText: 'PAN/VAT ID',
        hintText: 'Enter PAN or VAT number',
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.business_center),
      ),
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _buildInfoText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Parties are people you do business with. Use them for invoices and to keep track of your payables & receivables.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isLoading ? null : _saveAndNew,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text(
                'Save & New',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveParty,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE21B22),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(),
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
                  : const Text(
                      'Save Party',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: _asOfDate,
      isBikramSambat: true,
    );
    if (picked != null) {
      setState(() => _asOfDate = picked);
    }
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
      final balance = _isToReceive ? -openingBalance : openingBalance;

      await ref.read(customerActionsProvider.notifier).addCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _billingAddressController.text.trim().isEmpty ? null : _billingAddressController.text.trim(),
        panNumber: _panVatController.text.trim().isEmpty ? null : _panVatController.text.trim(),
        balance: balance,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Party "${_nameController.text.trim()}" saved successfully')),
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
    await _saveParty();
    if (mounted) {
      setState(() {
        _nameController.clear();
        _phoneController.clear();
        _openingBalanceController.clear();
        _billingAddressController.clear();
        _emailController.clear();
        _panVatController.clear();
        _asOfDate = DateTime.now();
        _isToReceive = false;
      });
    }
  }
}
