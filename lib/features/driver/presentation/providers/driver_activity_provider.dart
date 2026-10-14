import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/core/providers/repository_providers.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';

class DriverActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final String? route;

  const DriverActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.route,
  });
}

/// Derives real recent activities from driver trips, bookings, and notifications (Part 15)
final driverActivityProvider = FutureProvider<List<DriverActivityItem>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return [];

  final driverId = authState.user.uid;
  final tripRepo = ref.watch(tripRepositoryProvider);
  final firestore = ref.watch(firestoreProvider);

  final List<DriverActivityItem> items = [];

  try {
    // 1. Fetch recent trips
    final trips = await tripRepo.getDriverTrips(driverId);
    for (final trip in trips.take(10)) {
      final tripDate = trip.departureTime;
      String title;
      IconData icon;
      Color color;

      switch (trip.status) {
        case 'completed':
          title = 'اكتملت الرحلة (${trip.departureCity} - ${trip.arrivalCity})';
          icon = Icons.check_circle_rounded;
          color = const Color(0xFF2E7D32);
          break;
        case 'running':
          title = 'رحلة جارية (${trip.departureCity} - ${trip.arrivalCity})';
          icon = Icons.directions_car_filled_rounded;
          color = const Color(0xFFE65100);
          break;
        case 'cancelled':
          title =
              'تم إلغاء الرحلة (${trip.departureCity} - ${trip.arrivalCity})';
          icon = Icons.cancel_rounded;
          color = const Color(0xFFC62828);
          break;
        default:
          title = 'تم إنشاء رحلة (${trip.departureCity} - ${trip.arrivalCity})';
          icon = Icons.add_road_rounded;
          color = const Color(0xFF1565C0);
      }

      items.add(
        DriverActivityItem(
          id: 'trip_${trip.id}',
          title: title,
          subtitle: '${trip.departureCity} ➔ ${trip.arrivalCity}',
          timestamp: tripDate,
          icon: icon,
          color: color,
          route: '/driver-trip-details/${trip.id}',
        ),
      );
    }
  } catch (_) {}

  try {
    // 2. Fetch recent bookings
    final bookings = await tripRepo.getDriverBookings(driverId);
    for (final booking in bookings.take(15)) {
      final bDate =
          booking.updatedAt ?? booking.createdAt ?? booking.bookingTime;
      String title;
      IconData icon;
      Color color;

      switch (booking.status) {
        case 'payment_verification':
        case 'awaiting_driver_verification':
          title = 'إشعار سداد جديد من الراكب (${booking.name})';
          icon = Icons.payment_rounded;
          color = const Color(0xFFF57F17);
          break;
        case 'confirmed':
          title = 'تم تأكيد حجز الراكب (${booking.name})';
          icon = Icons.how_to_reg_rounded;
          color = const Color(0xFF2E7D32);
          break;
        case 'cancelled':
        case 'cancelled_by_passenger':
          title = 'إلغاء حجز الراكب (${booking.name})';
          icon = Icons.person_remove_rounded;
          color = const Color(0xFFC62828);
          break;
        default:
          title = 'طلب حجز جديد من (${booking.name})';
          icon = Icons.person_add_alt_1_rounded;
          color = const Color(0xFF1565C0);
      }

      items.add(
        DriverActivityItem(
          id: 'booking_${booking.id}',
          title: title,
          subtitle:
              'حجز #${booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.id.substring(0, 6)}',
          timestamp: bDate,
          icon: icon,
          color: color,
          route: '/driver-booking-details/${booking.id}',
        ),
      );
    }
  } catch (_) {}

  try {
    // 3. Fetch recent notifications
    final notifSnap = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    for (final doc in notifSnap.docs) {
      final data = doc.data();
      final dt = (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
      items.add(
        DriverActivityItem(
          id: 'notif_${doc.id}',
          title: data['title'] ?? 'إشعار نظام',
          subtitle: data['body'] ?? '',
          timestamp: dt,
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF0B1F3A),
        ),
      );
    }
  } catch (_) {}

  // Sort descending by actual timestamp
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items.take(20).toList();
});
