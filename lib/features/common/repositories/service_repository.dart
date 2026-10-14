import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<ServiceModel?> getById(String id);
  Future<void> create(ServiceModel item);
  Future<void> update(ServiceModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<ServiceModel>> watchAll();
  Stream<ServiceModel?> watchById(String id);
  Future<void> batchWrite(List<ServiceModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
