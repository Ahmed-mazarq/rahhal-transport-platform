import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';

abstract class BannerRepository {
  Future<List<BannerModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<BannerModel?> getById(String id);
  Future<void> create(BannerModel item);
  Future<void> update(BannerModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<BannerModel>> watchAll();
  Stream<BannerModel?> watchById(String id);
  Future<void> batchWrite(List<BannerModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
