import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(FirebaseFirestore.instance);
});

final notificationsProvider = StreamProvider<List<Notification>>((ref) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(notificationRepositoryProvider);

  if (authState is! Authenticated) {
    return Stream.value([]);
  }

  return repository.watchNotifications(
    authState.user.uid,
    userRole: authState.user.role,
  );
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final adminNotificationsProvider =
    StreamProvider.family<List<Notification>, String>((ref, status) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.watchAdminNotifications(status: status);
    });
