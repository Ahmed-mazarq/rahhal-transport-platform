import '../models/driver_profile.dart';
import '../models/payment_method.dart';
import '../models/driver_payment_method.dart';
import '../models/working_area.dart';
import '../models/driver_stats.dart';

abstract class DriverRepository {
  Future<DriverProfile?> getDriverProfile(String driverId);
  Future<void> updateDriverProfile(DriverProfile profile);
  Future<void> updateOnlineStatus(String driverId, bool isOnline);
  Future<void> addPaymentMethod(String driverId, PaymentMethod method);
  Future<void> updatePaymentMethod(String driverId, PaymentMethod method);
  Future<void> removePaymentMethod(String driverId, String methodId);
  Future<void> setPrimaryVehicle(String driverId, String vehicleId);
  Future<void> updateWorkingAreas(String driverId, List<WorkingArea> areas);
  Future<DriverStats> getDriverStatistics(String driverId);
  Future<void> updateDriverProfileImage(
    String driverId,
    String imageUrl,
    int updatedAt,
  );
  Future<void> updateDriverProfileInfo(
    String driverId,
    String fullName,
    String bio,
    String country,
    String emergencyContact,
  );

  // Modern canonical Driver Payment Methods (Part 46 & 47)
  Stream<List<DriverPaymentMethod>> watchDriverPaymentMethods(String driverId);
  Future<void> saveDriverPaymentMethod(DriverPaymentMethod method);
  Future<void> deleteDriverPaymentMethod(String methodId);
  Future<void> toggleDriverPaymentMethodActive(String methodId, bool isActive);
}
