import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/models/trip.dart';
import '../../../trips/domain/models/booking.dart';
import '../../../trips/domain/services/trip_search_service.dart';
import '../../../trips/presentation/providers/passenger_search_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../marketing/domain/models/offer.dart';
import 'package:rahal/core/providers/shared_trip_provider.dart';

// Stream for Suggested Trips (Real-time with deterministic personalization)
final dashboardSuggestedTripsProvider = Provider<AsyncValue<List<Trip>>>((ref) {
  final allTrips = ref.watch(sharedTripsProvider);
  final filterState = ref.watch(passengerSearchFilterProvider);
  final searchService = TripSearchService();

  return allTrips.whenData((trips) {
    final filter = TripSearchFilter(
      departureCountry: filterState.departureCountry,
      departureProvince: filterState.departureProvince,
      arrivalCountry: filterState.arrivalCountry,
      arrivalProvince: filterState.arrivalProvince,
      passengerCount: filterState.passengerCount,
    );

    if (!filter.isEmpty) {
      final searchResult = searchService.applyFilters(trips, filter);
      if (searchResult.trips.isNotEmpty) {
        return searchResult.trips.take(5).toList();
      }
    }

    final suggestions = searchService.getSuggestions(trips);
    return suggestions.take(5).toList();
  });
});

// Stream for Upcoming Bookings (Real-time, client-side filtered to avoid composite indexes)
final dashboardUpcomingBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return Stream.value([]);
  final user = authState.user;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  const upcomingStatuses = {
    'accepted',
    'confirmed',
    'pending_payment',
    'awaiting_payment',
    'payment_verification',
    'awaiting_driver_verification',
  };

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('passengerId', isEqualTo: user.id)
      .snapshots()
      .map((snapshot) {
        final bookings = snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Booking.fromJson(data);
            })
            .where((b) {
              if (!upcomingStatuses.contains(b.status)) return false;
              final bookingDate = b.travelDate;
              return bookingDate.isAfter(todayStart) ||
                  bookingDate.isAtSameMomentAs(todayStart);
            })
            .toList();

        bookings.sort((a, b) => a.travelDate.compareTo(b.travelDate));
        return bookings;
      });
});

// Composed Provider for Unread Notifications count (Reuses existing notification architecture)
final dashboardUnreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(unreadNotificationsCountProvider);
});

// Stream for Special Offers / Promotions (Typed with Offer domain model)
final dashboardOffersProvider = StreamProvider<List<Offer>>((ref) {
  return FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();
        final offers = snapshot.docs
            .map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return Offer.fromJson(data);
            })
            .where((offer) {
              return offer.expiryDate.isAfter(now);
            })
            .toList();

        offers.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        return offers;
      });
});
