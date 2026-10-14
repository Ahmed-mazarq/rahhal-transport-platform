import '../models/notification.dart';

abstract class NotificationRepository {
  Future<void> sendNotification(Notification notification);
  Future<void> sendBroadcastNotification(Notification notification);
  Stream<List<Notification>> watchNotifications(
    String userId, {
    String? userRole,
  });
  Stream<int> watchUnreadCount(String userId, {String? userRole});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);

  // Admin Methods
  Future<void> saveDraft(Notification notification);
  Future<void> updateNotification(Notification notification);
  Stream<List<Notification>> watchAdminNotifications({String? status});
}
