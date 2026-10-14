import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

abstract class NewsRepository {
  Future<List<NewsModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<NewsModel?> getById(String id);
  Future<void> create(NewsModel item);
  Future<void> update(NewsModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<NewsModel>> watchAll();
  Stream<NewsModel?> watchById(String id);
  Future<void> batchWrite(List<NewsModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
