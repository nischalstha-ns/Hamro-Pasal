class BusinessProfile {
  final String businessName;
  final String? logoPath;
  final String? address;
  final String? phone;
  final String? email;
  final String? panNumber;

  const BusinessProfile({
    required this.businessName,
    this.logoPath,
    this.address,
    this.phone,
    this.email,
    this.panNumber,
  });

  factory BusinessProfile.empty() {
    return const BusinessProfile(businessName: '');
  }

  BusinessProfile copyWith({
    String? businessName,
    String? logoPath,
    String? address,
    String? phone,
    String? email,
    String? panNumber,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      logoPath: logoPath ?? this.logoPath,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      panNumber: panNumber ?? this.panNumber,
    );
  }
}
