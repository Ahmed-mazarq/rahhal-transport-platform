import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';

abstract class CityRepository {
  Future<List<CityModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<CityModel?> getById(String id);
  Future<void> create(CityModel item);
  Future<void> update(CityModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<CityModel>> watchAll();
  Stream<CityModel?> watchById(String id);
  Future<void> batchWrite(List<CityModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
