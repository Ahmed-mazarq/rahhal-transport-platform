import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

abstract class NewsService {
  Future<List<NewsModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<NewsModel?> fetchById(String id);
  Future<void> save(NewsModel item);
  Future<void> update(NewsModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<NewsModel>> streamAll();
  Stream<NewsModel?> streamById(String id);
  Future<void> batchWrite(List<NewsModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
