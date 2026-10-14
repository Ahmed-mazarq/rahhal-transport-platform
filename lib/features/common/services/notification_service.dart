import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

abstract class NotificationService {
  Future<List<NotificationModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<NotificationModel?> fetchById(String id);
  Future<void> save(NotificationModel item);
  Future<void> update(NotificationModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<NotificationModel>> streamAll();
  Stream<NotificationModel?> streamById(String id);
  Future<void> batchWrite(List<NotificationModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
