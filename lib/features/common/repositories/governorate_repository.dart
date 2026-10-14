import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/governorate_model.dart';

abstract class GovernorateRepository {
  Future<List<GovernorateModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<GovernorateModel?> getById(String id);
  Future<void> create(GovernorateModel item);
  Future<void> update(GovernorateModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<GovernorateModel>> watchAll();
  Stream<GovernorateModel?> watchById(String id);
  Future<void> batchWrite(List<GovernorateModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
