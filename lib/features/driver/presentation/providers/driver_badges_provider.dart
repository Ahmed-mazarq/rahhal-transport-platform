import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Provider for bookings requiring Driver action (e.g. verify payment proof, confirm booking, review support)
final driverActionRequiredBookingsCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return Stream.value(0);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('bookings')
      .where('driverId', isEqualTo: authState.user.uid)
      .where(
        'status',
        whereIn: [
          'payment_verification',
          'awaiting_driver_verification',
          'pending',
          'support_review',
        ],
      )
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Kept for backward compatibility, delegates to driverActionRequiredBookingsCountProvider
final driverPendingBookingsCountProvider =
    driverActionRequiredBookingsCountProvider;

final driverUnreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return Stream.value(0);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('notifications')
      .where('userId', isEqualTo: authState.user.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
