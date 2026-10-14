import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';

abstract class DriverRepository {
  Future<List<DriverModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<DriverModel?> getById(String id);
  Future<void> create(DriverModel item);
  Future<void> update(DriverModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<DriverModel>> watchAll();
  Stream<DriverModel?> watchById(String id);
  Future<void> batchWrite(List<DriverModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
