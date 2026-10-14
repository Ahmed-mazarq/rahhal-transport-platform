import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

abstract class RatingRepository {
  Future<List<RatingModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<RatingModel?> getById(String id);
  Future<void> create(RatingModel item);
  Future<void> update(RatingModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<RatingModel>> watchAll();
  Stream<RatingModel?> watchById(String id);
  Future<void> batchWrite(List<RatingModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
