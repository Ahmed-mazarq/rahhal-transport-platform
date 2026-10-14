import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

abstract class ServiceService {
  Future<List<ServiceModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<ServiceModel?> fetchById(String id);
  Future<void> save(ServiceModel item);
  Future<void> update(ServiceModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<ServiceModel>> streamAll();
  Stream<ServiceModel?> streamById(String id);
  Future<void> batchWrite(List<ServiceModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
