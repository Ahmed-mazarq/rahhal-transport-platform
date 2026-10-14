import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

abstract class VehicleRepository {
  Future<List<VehicleModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<VehicleModel?> getById(String id);
  Future<void> create(VehicleModel item);
  Future<void> update(VehicleModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<VehicleModel>> watchAll();
  Stream<VehicleModel?> watchById(String id);
  Future<void> batchWrite(List<VehicleModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
