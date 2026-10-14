import '../../../common/models/user_model.dart';
import '../../../common/models/driver_model.dart';
import '../../../common/models/company_model.dart';
import '../../../passenger/domain/models/passenger_profile.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String phone, String password);
  Future<UserModel?> signUp({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    Map<String, dynamic>? roleFields,
  });
  Future<void> signOut();
  Stream<UserModel?> watchAuthState();
  Future<bool> isPhoneUnique(String phone);
  Future<UserModel?> getCurrentUser(String uid);
  Future<PassengerProfile?> getPassengerProfile(String uid);
  Future<DriverModel?> getDriverProfile(String uid);
  Future<CompanyModel?> getCompanyProfile(String uid);
  Future<void> updateDriverOnlineStatus(String uid, bool isOnline);
  Future<void> updateDriverProfile(DriverModel driver);
  Future<void> updateCompanyOnlineStatus(String uid, bool isOnline);
  Future<void> updateCompanyProfile(CompanyModel profile);
  Future<void> updateUserProfile(UserModel user);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
