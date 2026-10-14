import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertisement_model.dart';

abstract class AdvertisementRepository {
  Future<List<AdvertisementModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<AdvertisementModel?> getById(String id);
  Future<void> create(AdvertisementModel item);
  Future<void> update(AdvertisementModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<AdvertisementModel>> watchAll();
  Stream<AdvertisementModel?> watchById(String id);
  Future<void> batchWrite(List<AdvertisementModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
