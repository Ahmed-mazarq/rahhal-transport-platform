import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../features/notifications/domain/models/notification.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';

class SystemNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _notificationRepository = NotificationRepositoryImpl(_firestore);

  static Future<void> sendNotification({
    required String title,
    required String body,
    required String targetUserId,
    required String category,
    String targetRole = 'all',
    Map<String, dynamic> payload = const {},
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw StateError('Authenticated user is required to create a notification.');
    }

    final notification = Notification(
      id: const Uuid().v4(),
      userId: targetUserId,
      title: title,
      body: body,
      category: category,
      priority: 'normal',
      status: 'sent',
      createdAt: DateTime.now(),
      createdBy: currentUid,
      targetRole: targetRole,
      isRead: false,
      payload: payload,
      sentAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notification);
  }
}
