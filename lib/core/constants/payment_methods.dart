enum PaymentMethod {
  cash('Cash', 'नगद'),
  esewa('eSewa', 'ईसेवा'),
  khalti('Khalti', 'खल्ती'),
  fonepay('fonepay', 'फोनपे'),
  bankTransfer('Bank Transfer', 'बैंक ट्रान्सफर'),
  credit('Credit', 'उधारो');

  const PaymentMethod(this.nameEn, this.nameNe);

  final String nameEn;
  final String nameNe;

  String getName(bool isNepali) => isNepali ? nameNe : nameEn;
}

enum TransactionType {
  sale('Sale', 'बिक्री'),
  purchase('Purchase', 'खरिद'),
  payment('Payment', 'भुक्तानी'),
  receipt('Receipt', 'रसिद'),
  expense('Expense', 'खर्च');

  const TransactionType(this.nameEn, this.nameNe);

  final String nameEn;
  final String nameNe;

  String getName(bool isNepali) => isNepali ? nameNe : nameEn;
}
