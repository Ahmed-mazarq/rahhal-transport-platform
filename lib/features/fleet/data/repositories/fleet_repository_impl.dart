import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/repositories/fleet_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  FleetRepositoryImpl(this._firestore, this._ref);

  void _checkApproval() {
    final authState = _ref.read(authProvider);
    if (authState is Authenticated) {
      final user = authState.user;
      if ((user.role == 'driver' || user.role == 'company') &&
          user.status != 'approved') {
        throw Exception(
          'لا يمكنك إجراء هذه العملية حتى يتم اعتماد حسابك من الإدارة.',
        );
      }
    }
  }

  @override
  Future<void> addVehicle(Vehicle vehicle) async {
    _checkApproval();
    await _firestore
        .collection('vehicles')
        .doc(vehicle.id)
        .set(vehicle.toJson());
  }

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    _checkApproval();
    await _firestore
        .collection('vehicles')
        .doc(vehicle.id)
        .set(vehicle.toJson(), SetOptions(merge: true));
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    final doc = await _firestore.collection('vehicles').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Vehicle.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<Vehicle?> getDriverVehicle(String driverId) async {
    final query = await _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Vehicle.fromJson(query.docs.first.data());
    }

    // Fallback to first vehicle if no default exists
    final fallbackQuery = await _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();

    if (fallbackQuery.docs.isNotEmpty) {
      return Vehicle.fromJson(fallbackQuery.docs.first.data());
    }

    return null;
  }

  @override
  Future<List<Vehicle>> getDriverVehicles(String driverId) async {
    final query = await _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
        .get();
    return query.docs.map((doc) => Vehicle.fromJson(doc.data())).toList();
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _firestore.collection('vehicles').doc(id).delete();
  }

  @override
  Future<void> setDefaultVehicle(String driverId, String vehicleId) async {
    final vehicles = await getDriverVehicles(driverId);
    final batch = _firestore.batch();

    for (var vehicle in vehicles) {
      final docRef = _firestore.collection('vehicles').doc(vehicle.id);
      batch.update(docRef, {'isDefault': vehicle.id == vehicleId});
    }

    await batch.commit();
  }

  @override
  Future<void> ensureLegacyVehicleMigrated(String driverId) async {
    final existing = await getDriverVehicles(driverId);
    if (existing.isNotEmpty) return;

    final driverDoc = await _firestore
        .collection('drivers')
        .doc(driverId)
        .get();
    if (!driverDoc.exists) return;
    final data = driverDoc.data()!;
    final manufacturer = data['vehicleManufacturer']?.toString() ?? '';
    if (manufacturer.isEmpty) return;

    String vehicleId = data['vehicleId']?.toString() ?? '';
    if (vehicleId.isEmpty) {
      vehicleId = 'veh_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('drivers').doc(driverId).update({
        'vehicleId': vehicleId,
      });
    }

    final vehicleDoc = await _firestore
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    if (!vehicleDoc.exists) {
      final docs = data['documents'] as Map<String, dynamic>? ?? {};
      String getDocUrl(String key) {
        if (docs[key] != null && docs[key] is Map) {
          return docs[key]['url']?.toString() ?? '';
        }
        return '';
      }

      final migratedVehicle = Vehicle(
        id: vehicleId,
        driverId: driverId,
        make: data['vehicleManufacturer']?.toString() ?? '',
        model: data['vehicleModel']?.toString() ?? '',
        year:
            int.tryParse(data['vehicleYear']?.toString() ?? '') ??
            DateTime.now().year,
        color: data['vehicleColor']?.toString() ?? '',
        plateNumber: data['plateNumber']?.toString() ?? '',
        vin: data['vin']?.toString() ?? '',
        registrationNumber: data['registrationNumber']?.toString() ?? '',
        insuranceNumber: data['insuranceNumber']?.toString() ?? '',
        type: data['vehicleType']?.toString() ?? 'سيارة',
        fuelType: data['fuelType']?.toString() ?? 'بنزين',
        seatsCount: int.tryParse(data['seatCount']?.toString() ?? '') ?? 4,
        status: 'Available',
        photoUrl: getDocUrl('vehicleFront'),
        additionalPhotos: [
          if (getDocUrl('vehicleBack').isNotEmpty) getDocUrl('vehicleBack'),
          if (getDocUrl('vehicleRight').isNotEmpty) getDocUrl('vehicleRight'),
          if (getDocUrl('vehicleLeft').isNotEmpty) getDocUrl('vehicleLeft'),
          if (getDocUrl('vehicleInterior').isNotEmpty)
            getDocUrl('vehicleInterior'),
        ],
        isDefault: true,
      );

      await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .set(migratedVehicle.toJson());
    }
  }

  @override
  Future<void> addMaintenanceRecord(
    String vehicleId,
    MaintenanceRecord record,
  ) async {
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) return;
    final updatedList = List<MaintenanceRecord>.from(vehicle.maintenanceRecords)
      ..add(record);
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'maintenanceRecords': updatedList.map((r) => r.toJson()).toList(),
    });
  }

  @override
  Future<void> deleteMaintenanceRecord(
    String vehicleId,
    String recordId,
  ) async {
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) return;
    final updatedList = vehicle.maintenanceRecords
        .where((r) => r.id != recordId)
        .toList();
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'maintenanceRecords': updatedList.map((r) => r.toJson()).toList(),
    });
  }
}
