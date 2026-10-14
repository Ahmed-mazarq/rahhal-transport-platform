import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/verification_request.dart';
import '../../domain/models/driver_document.dart';
import '../../domain/models/vehicle_document.dart';
import '../../domain/repositories/verification_repository.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final FirebaseFirestore _firestore;

  VerificationRepositoryImpl(this._firestore);

  @override
  Future<void> submitVerificationRequest(VerificationRequest request) async {
    await _firestore
        .collection('verification_requests')
        .doc(request.id)
        .set(request.toJson());
  }

  @override
  Future<void> uploadDriverDocument(DriverDocument doc) async {
    await _firestore
        .collection('driver_documents')
        .doc(doc.id)
        .set(doc.toJson());
  }

  @override
  Future<void> uploadVehicleDocument(VehicleDocument doc) async {
    await _firestore
        .collection('vehicle_documents')
        .doc(doc.id)
        .set(doc.toJson());
  }

  @override
  Future<List<DriverDocument>> getDriverDocuments(String driverId) async {
    final snapshot = await _firestore
        .collection('driver_documents')
        .where('driverId', isEqualTo: driverId)
        .get();
    return snapshot.docs
        .map((doc) => DriverDocument.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<VehicleDocument>> getVehicleDocuments(String vehicleId) async {
    final snapshot = await _firestore
        .collection('vehicle_documents')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();
    return snapshot.docs
        .map((doc) => VehicleDocument.fromJson(doc.data()))
        .toList();
  }
}
