import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl(this._firestore);

  @override
  Future<void> sendNotification(Notification notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toJson());
  }

  @override
  Future<void> sendBroadcastNotification(Notification notification) async {
    Query<Map<String, dynamic>> usersQuery = _firestore.collection('users');

    if (notification.targetRole != 'all') {
      usersQuery = usersQuery.where('role', isEqualTo: notification.targetRole);
    }

    final usersSnapshot = await usersQuery.get();

    final batch = _firestore.batch();
    int count = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      final individualNotification = notification.copyWith(
        id: const Uuid().v4(),
        userId: userId,
      );

      final docRef = _firestore
          .collection('notifications')
          .doc(individualNotification.id);
      batch.set(docRef, individualNotification.toJson());

      count++;
      if (count >= 500) {
        await batch.commit();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  @override
  Stream<List<Notification>> watchNotifications(
    String userId, {
    String? userRole,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('notifications');

    // Only show 'sent' or 'scheduled' notifications to users, not drafts
    query = query.where('status', whereIn: ['sent', 'scheduled']);

    // Since broadcasts now generate individual documents, we just filter by userId.
    query = query.where('userId', isEqualTo: userId);

    return query.snapshots().map((snapshot) {
      final notifs = snapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
      notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifs;
    });
  }

  @override
  Stream<int> watchUnreadCount(String userId, {String? userRole}) {
    return watchNotifications(
      userId,
      userRole: userRole,
    ).map((notifs) => notifs.where((n) => !n.isRead).length);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readCount': FieldValue.increment(1),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // --- Admin Methods ---

  @override
  Future<void> saveDraft(Notification notification) async {
    final draft = notification.copyWith(status: 'draft');
    await _firestore
        .collection('notifications')
        .doc(draft.id)
        .set(draft.toJson());
  }

  @override
  Future<void> updateNotification(Notification notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .update(notification.toJson());
  }

  @override
  Stream<List<Notification>> watchAdminNotifications({String? status}) {
    Query<Map<String, dynamic>> query = _firestore.collection('notifications');

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      final notifs = snapshot.docs
          .map((doc) => Notification.fromJson(doc.data()))
          .toList();
      notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifs;
    });
  }
}
