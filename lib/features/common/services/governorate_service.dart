import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/governorate_model.dart';

abstract class GovernorateService {
  Future<List<GovernorateModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<GovernorateModel?> fetchById(String id);
  Future<void> save(GovernorateModel item);
  Future<void> update(GovernorateModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<GovernorateModel>> streamAll();
  Stream<GovernorateModel?> streamById(String id);
  Future<void> batchWrite(List<GovernorateModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
