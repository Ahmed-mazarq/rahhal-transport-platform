import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';

abstract class DriverService {
  Future<List<DriverModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<DriverModel?> fetchById(String id);
  Future<void> save(DriverModel item);
  Future<void> update(DriverModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<DriverModel>> streamAll();
  Stream<DriverModel?> streamById(String id);
  Future<void> batchWrite(List<DriverModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
