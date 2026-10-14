import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

abstract class VehicleService {
  Future<List<VehicleModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<VehicleModel?> fetchById(String id);
  Future<void> save(VehicleModel item);
  Future<void> update(VehicleModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<VehicleModel>> streamAll();
  Stream<VehicleModel?> streamById(String id);
  Future<void> batchWrite(List<VehicleModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
