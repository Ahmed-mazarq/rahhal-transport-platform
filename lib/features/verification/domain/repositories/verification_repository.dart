import '../models/verification_request.dart';
import '../models/driver_document.dart';
import '../models/vehicle_document.dart';

abstract class VerificationRepository {
  Future<void> submitVerificationRequest(VerificationRequest request);
  Future<void> uploadDriverDocument(DriverDocument doc);
  Future<void> uploadVehicleDocument(VehicleDocument doc);
  Future<List<DriverDocument>> getDriverDocuments(String driverId);
  Future<List<VehicleDocument>> getVehicleDocuments(String vehicleId);
}
