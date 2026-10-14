import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

abstract class RatingService {
  Future<List<RatingModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<RatingModel?> fetchById(String id);
  Future<void> save(RatingModel item);
  Future<void> update(RatingModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<RatingModel>> streamAll();
  Stream<RatingModel?> streamById(String id);
  Future<void> batchWrite(List<RatingModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
