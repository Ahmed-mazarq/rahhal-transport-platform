import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<NotificationModel?> getById(String id);
  Future<void> create(NotificationModel item);
  Future<void> update(NotificationModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<NotificationModel>> watchAll();
  Stream<NotificationModel?> watchById(String id);
  Future<void> batchWrite(List<NotificationModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
