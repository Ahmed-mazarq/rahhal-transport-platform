import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';

abstract class SettingsRepository {
  Future<List<SettingsModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<SettingsModel?> getById(String id);
  Future<void> create(SettingsModel item);
  Future<void> update(SettingsModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<SettingsModel>> watchAll();
  Stream<SettingsModel?> watchById(String id);
  Future<void> batchWrite(List<SettingsModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
