import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';

abstract class SettingsService {
  Future<List<SettingsModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<SettingsModel?> fetchById(String id);
  Future<void> save(SettingsModel item);
  Future<void> update(SettingsModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<SettingsModel>> streamAll();
  Stream<SettingsModel?> streamById(String id);
  Future<void> batchWrite(List<SettingsModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
