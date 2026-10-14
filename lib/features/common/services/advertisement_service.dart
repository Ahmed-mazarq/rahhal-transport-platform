import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertisement_model.dart';

abstract class AdvertisementService {
  Future<List<AdvertisementModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<AdvertisementModel?> fetchById(String id);
  Future<void> save(AdvertisementModel item);
  Future<void> update(AdvertisementModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<AdvertisementModel>> streamAll();
  Stream<AdvertisementModel?> streamById(String id);
  Future<void> batchWrite(List<AdvertisementModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
