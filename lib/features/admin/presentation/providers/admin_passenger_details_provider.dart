import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/features/trips/domain/models/trip_request.dart';
import 'package:rahal/features/common/models/user_model.dart';
import 'package:rahal/features/passenger/domain/models/passenger_profile.dart';

class PassengerCounts {
  final int totalBookings;
  final int currentBookings; // confirmed, accepted
  final int pendingBookings; // pending, awaiting...
  final int completedBookings; // completed
  final int cancelledBookings;
  final int upcomingTrips;
  final int currentTrips;
  final int completedTrips;
  final int tripRequests;

  PassengerCounts({
    this.totalBookings = 0,
    this.currentBookings = 0,
    this.pendingBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.upcomingTrips = 0,
    this.currentTrips = 0,
    this.completedTrips = 0,
    this.tripRequests = 0,
  });
}

class PassengerDetailsState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final PassengerProfile? profile;
  final List<Booking> bookings;
  final List<TripRequest> tripRequests;
  final Map<String, Trip> tripCache;
  final PassengerCounts counts;

  PassengerDetailsState({
    this.isLoading = true,
    this.error,
    this.user,
    this.profile,
    this.bookings = const [],
    this.tripRequests = const [],
    this.tripCache = const {},
    PassengerCounts? counts,
  }) : counts = counts ?? PassengerCounts();

  PassengerDetailsState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    PassengerProfile? profile,
    List<Booking>? bookings,
    List<TripRequest>? tripRequests,
    Map<String, Trip>? tripCache,
    PassengerCounts? counts,
  }) {
    return PassengerDetailsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      bookings: bookings ?? this.bookings,
      tripRequests: tripRequests ?? this.tripRequests,
      tripCache: tripCache ?? this.tripCache,
      counts: counts ?? this.counts,
    );
  }
}

class PassengerDetailsNotifier extends StateNotifier<PassengerDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PassengerDetailsNotifier() : super(PassengerDetailsState());

  Future<void> fetchData(String passengerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Fetch user, passenger, bookings, and trip_requests in parallel
      final results = await Future.wait([
        _firestore.collection('users').doc(passengerId).get(),
        _firestore.collection('passengers').doc(passengerId).get(),
        _firestore
            .collection('bookings')
            .where('passengerId', isEqualTo: passengerId)
            .get(),
        _firestore
            .collection('trip_requests')
            .where('passengerId', isEqualTo: passengerId)
            .get(),
      ]);

      final userSnapshot = results[0] as DocumentSnapshot;
      final passengerSnapshot = results[1] as DocumentSnapshot;
      final bookingsSnapshot = results[2] as QuerySnapshot;
      final requestsSnapshot = results[3] as QuerySnapshot;

      UserModel? user;
      if (userSnapshot.exists) {
        user = UserModel.fromFirestore(
          userSnapshot.data() as Map<String, dynamic>,
          userSnapshot.id,
        );
      }

      PassengerProfile? profile;
      if (passengerSnapshot.exists) {
        final data = passengerSnapshot.data() as Map<String, dynamic>;
        data['uid'] = passengerSnapshot.id;
        profile = PassengerProfile.fromJson(data);
      }

      List<Booking> bookings = bookingsSnapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id; // ensure ID is set
        return Booking.fromJson(data);
      }).toList();

      // Sort bookings by creation date locally to avoid composite index
      bookings.sort((a, b) {
        final dateA = a.createdAt ?? a.bookingTime;
        final dateB = b.createdAt ?? b.bookingTime;
        return dateB.compareTo(dateA);
      });

      List<TripRequest> tripRequests = requestsSnapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return TripRequest.fromJson(data);
      }).toList();

      tripRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 2. Extract unique tripIds
      final Set<String> tripIds = bookings
          .map((b) => b.tripId)
          .where((id) => id.isNotEmpty)
          .toSet();

      // 3. Fetch missing trips in chunks of 10 to respect whereIn limits
      Map<String, Trip> tripCache = {};
      final List<String> tripIdsList = tripIds.toList();
      for (int i = 0; i < tripIdsList.length; i += 10) {
        final chunk = tripIdsList.sublist(
          i,
          i + 10 > tripIdsList.length ? tripIdsList.length : i + 10,
        );
        final tripsSnapshot = await _firestore
            .collection('trips')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in tripsSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          tripCache[doc.id] = Trip.fromJson(data);
        }
      }

      // 4. Calculate counts and categorizations
      int currentBookings = 0,
          pendingBookings = 0,
          completedBookings = 0,
          cancelledBookings = 0;
      for (var b in bookings) {
        if ([
          'pending',
          'awaiting_payment',
          'pending_payment',
          'payment_verification',
          'awaiting_driver_verification',
          'support_review',
        ].contains(b.status)) {
          pendingBookings++;
        } else if (['confirmed', 'accepted'].contains(b.status)) {
          currentBookings++;
        } else if (b.status == 'completed') {
          completedBookings++;
        } else {
          cancelledBookings++;
        }
      }

      int upcomingTrips = 0, currentTrips = 0, completedTrips = 0;
      final Set<String> processedTrips = {}; // count each trip once
      final now = DateTime.now();

      for (var b in bookings) {
        if (!processedTrips.contains(b.tripId) &&
            tripCache.containsKey(b.tripId)) {
          final trip = tripCache[b.tripId]!;
          processedTrips.add(trip.id);

          if (['completed', 'finished'].contains(trip.status)) {
            completedTrips++;
          } else if (['active', 'running', 'started'].contains(trip.status)) {
            currentTrips++;
          } else if (['published', 'scheduled'].contains(trip.status)) {
            // classify as current if now is between departure and arrival, else upcoming
            if (now.isAfter(trip.departureTime) &&
                now.isBefore(trip.arrivalTime)) {
              currentTrips++;
            } else {
              upcomingTrips++;
            }
          }
        }
      }

      final counts = PassengerCounts(
        totalBookings: bookings.length,
        currentBookings: currentBookings,
        pendingBookings: pendingBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
        upcomingTrips: upcomingTrips,
        currentTrips: currentTrips,
        completedTrips: completedTrips,
        tripRequests: tripRequests.length,
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
        profile: profile,
        bookings: bookings,
        tripRequests: tripRequests,
        tripCache: tripCache,
        counts: counts,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final passengerDetailsProvider =
    StateNotifierProvider.family<
      PassengerDetailsNotifier,
      PassengerDetailsState,
      String
    >((ref, passengerId) {
      return PassengerDetailsNotifier()..fetchData(passengerId);
    });
