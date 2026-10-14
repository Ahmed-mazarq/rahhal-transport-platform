import '../models/vehicle.dart';

abstract class FleetRepository {
  Future<void> addVehicle(Vehicle vehicle);
  Future<void> updateVehicle(Vehicle vehicle);
  Future<Vehicle?> getVehicle(String id);
  Future<Vehicle?> getDriverVehicle(String driverId);
  Future<List<Vehicle>> getDriverVehicles(String driverId);
  Future<void> deleteVehicle(String id);
  Future<void> setDefaultVehicle(String driverId, String vehicleId);
  Future<void> ensureLegacyVehicleMigrated(String driverId);
  Future<void> addMaintenanceRecord(String vehicleId, MaintenanceRecord record);
  Future<void> deleteMaintenanceRecord(String vehicleId, String recordId);
}
