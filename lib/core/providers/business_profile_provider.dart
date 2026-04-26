import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/products/providers/products_provider.dart';
import '../models/business_profile.dart';

part 'business_profile_provider.g.dart';

@riverpod
class BusinessProfileNotifier extends _$BusinessProfileNotifier {
  @override
  Future<BusinessProfile> build() async {
    final db = ref.watch(appDatabaseProvider);
    
    final businessName = await db.getSetting('business_name') ?? '';
    final logoPath = await db.getSetting('business_logo');
    final address = await db.getSetting('business_address');
    final phone = await db.getSetting('business_phone');
    final email = await db.getSetting('business_email');
    final panNumber = await db.getSetting('business_pan');

    return BusinessProfile(
      businessName: businessName,
      logoPath: (logoPath != null && logoPath.isNotEmpty) ? logoPath : null,
      address: address,
      phone: phone,
      email: email,
      panNumber: panNumber,
    );
  }

  Future<void> updateProfile(BusinessProfile profile) async {
    final db = ref.read(appDatabaseProvider);
    
    await db.setSetting('business_name', profile.businessName);
    
    if (profile.logoPath != null && profile.logoPath!.isNotEmpty) {
      await db.setSetting('business_logo', profile.logoPath!);
    } else {
      // Remove logo if null or empty
      await db.setSetting('business_logo', '');
    }
    
    if (profile.address != null && profile.address!.isNotEmpty) {
      await db.setSetting('business_address', profile.address!);
    }
    if (profile.phone != null && profile.phone!.isNotEmpty) {
      await db.setSetting('business_phone', profile.phone!);
    }
    if (profile.email != null && profile.email!.isNotEmpty) {
      await db.setSetting('business_email', profile.email!);
    }
    if (profile.panNumber != null && profile.panNumber!.isNotEmpty) {
      await db.setSetting('business_pan', profile.panNumber!);
    }

    ref.invalidateSelf();
  }
}
