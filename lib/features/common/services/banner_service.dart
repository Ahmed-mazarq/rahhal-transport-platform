import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

abstract class BannerService {
  Future<List<BannerModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<BannerModel?> fetchById(String id);
  Future<void> save(BannerModel item);
  Future<void> update(BannerModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<BannerModel>> streamAll();
  Stream<BannerModel?> streamById(String id);
  Future<void> batchWrite(List<BannerModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
