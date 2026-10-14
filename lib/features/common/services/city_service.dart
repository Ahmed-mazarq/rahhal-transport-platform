import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';

abstract class CityService {
  Future<List<CityModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<CityModel?> fetchById(String id);
  Future<void> save(CityModel item);
  Future<void> update(CityModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<CityModel>> streamAll();
  Stream<CityModel?> streamById(String id);
  Future<void> batchWrite(List<CityModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
