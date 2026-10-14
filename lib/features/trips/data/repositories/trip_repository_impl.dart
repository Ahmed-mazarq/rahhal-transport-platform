import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_request.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/stop.dart';
import '../../domain/models/seat.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../../../core/services/notification_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class TripRepositoryImpl implements TripRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  TripRepositoryImpl(this._firestore, this._ref);

  void _checkApproval() {
    final authState = _ref.read(authProvider);
    if (authState is Authenticated) {
      final user = authState.user;
      if ((user.role == 'driver' || user.role == 'company') &&
          user.status != 'approved') {
        throw Exception(
          'لا يمكنك إجراء هذه العملية حتى يتم اعتماد حسابك من الإدارة.',
        );
      }
    }
  }

  @override
  Future<void> createTripRequest(TripRequest request) async {
    _checkApproval();
    await _firestore
        .collection('trip_requests')
        .doc(request.id)
        .set(request.toJson());
  }

  @override
  Stream<TripRequest?> watchTripRequest(String requestId) {
    return _firestore
        .collection('trip_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return TripRequest.fromJson(doc.data()!);
          }
          return null;
        });
  }

  @override
  Future<void> createTrip(Trip trip) async {
    _checkApproval();

    // Ensure that a newly created trip is never accidentally stored as 'cancelled'
    // It should be 'published' (or 'draft' if duplicated, but never 'cancelled')
    if (trip.status == 'cancelled') {
      trip = trip.copyWith(status: 'published');
    }

    final json = trip.toJson();
    debugPrint(
      '=== CREATE TRIP SAVED JSON ===\nID: ${trip.id}\nJSON: $json\n===============================',
    );
    await _firestore.collection('trips').doc(trip.id).set(json);
  }

  @override
  Future<Trip?> getTrip(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (doc.exists && doc.data() != null) {
      return Trip.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> updateTripStatus(String tripId, String status) async {
    _checkApproval();
    await _firestore.collection('trips').doc(tripId).update({'status': status});

    // Notify passengers and driver about trip status change
    final trip = await getTrip(tripId);
    if (trip != null) {
      if (status == 'active' ||
          status == 'started' ||
          status == 'completed' ||
          status == 'finished') {
        final snapshot = await _firestore
            .collection('bookings')
            .where('tripId', isEqualTo: tripId)
            .get();

        final title = (status == 'active' || status == 'started')
            ? 'الرحلة بدأت'
            : 'الرحلة انتهت';
        final body = (status == 'active' || status == 'started')
            ? 'بدأت رحلتك إلى ${trip.arrivalCity}. نتمنى لك رحلة آمنة.'
            : 'انتهت رحلتك إلى ${trip.arrivalCity}. شكراً لاختيارك رحال.';

        for (var doc in snapshot.docs) {
          final booking = Booking.fromJson(doc.data());
          if (booking.status == 'confirmed' || booking.status == 'accepted') {
            await SystemNotificationService.sendNotification(
              title: title,
              body: body,
              targetUserId: booking.passengerId,
              category: 'trip',
              targetRole: 'passenger',
            );
          }
        }

        // Notify driver
        await SystemNotificationService.sendNotification(
          title: title,
          body: body,
          targetUserId: trip.driverId,
          category: 'trip',
          targetRole: 'driver',
        );
      }
    }
  }

  @override
  Future<void> createBooking(Booking booking) async {
    // Create the booking document
    await _firestore
        .collection('bookings')
        .doc(booking.id)
        .set(booking.toJson());

    // Decrement the remaining seats on the associated Trip document
    final tripDoc = _firestore.collection('trips').doc(booking.tripId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tripDoc);
      if (snapshot.exists && snapshot.data() != null) {
        final trip = Trip.fromJson(snapshot.data()!);
        final newRemaining = (trip.remainingSeats - booking.seatCount.toInt())
            .clamp(0, trip.totalSeats);
        transaction.update(tripDoc, {'remainingSeats': newRemaining});
      }
    });

    // Notify driver
    await SystemNotificationService.sendNotification(
      title: 'حجز جديد',
      body: 'تم حجز ${booking.seatCount} مقعد في رحلتك.',
      targetUserId: booking.driverId,
      category: 'booking',
      targetRole: 'driver',
    );
  }

  @override
  Future<List<Booking>> getPassengerBookings(String passengerId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('passengerId', isEqualTo: passengerId)
        .get();
    return snapshot.docs.map((doc) => Booking.fromJson(doc.data())).toList();
  }

  @override
  Future<List<Booking>> getDriverBookings(String driverId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('driverId', isEqualTo: driverId)
        .get();
    return snapshot.docs.map((doc) => Booking.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<Booking>> watchDriverBookings(String driverId) {
    debugPrint(
      '[DRIVER_BOOKINGS_DEBUG] authStateUserId / queryDriverId: $driverId',
    );
    return _firestore
        .collection('bookings')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '[DRIVER_BOOKINGS_DEBUG] numberOfDocumentsReturned: ${snapshot.docs.length}',
          );
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // PART 9: Make repository authoritative
            final booking = Booking.fromJson(data);
            debugPrint(
              '[DRIVER_BOOKINGS_DEBUG] bookingId: ${booking.id}, driverId: ${booking.driverId}, status: ${booking.status}, tripId: ${booking.tripId}',
            );
            return booking;
          }).toList();
        });
  }

  @override
  Future<List<Trip>> getDriverTrips(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .get();
    return snapshot.docs.map((doc) => Trip.fromJson(doc.data())).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPassengerRecentBookingInteractions(
    String passengerId,
  ) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('passengerId', isEqualTo: passengerId)
        .orderBy('bookingTime', descending: true)
        .limit(20)
        .get();

    final interactions = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final booking = Booking.fromJson(doc.data()..['id'] = doc.id);

      try {
        final tripDoc = await _firestore
            .collection('trips')
            .doc(booking.tripId)
            .get();
        if (tripDoc.exists && tripDoc.data() != null) {
          final trip = Trip.fromJson(tripDoc.data()!);

          String targetName = trip.driverName;
          String targetAvatar = trip.driverAvatar;

          if (trip.isCompany) {
            final companyDoc = await _firestore
                .collection('companies')
                .doc(trip.companyId)
                .get();
            if (companyDoc.exists && companyDoc.data() != null) {
              targetName = companyDoc.data()!['name'] ?? targetName;
              targetAvatar = companyDoc.data()!['logo'] ?? targetAvatar;
            }
          } else {
            final driverDoc = await _firestore
                .collection('drivers')
                .doc(trip.driverId)
                .get();
            if (driverDoc.exists && driverDoc.data() != null) {
              targetName = driverDoc.data()!['fullName'] ?? targetName;
              targetAvatar = driverDoc.data()!['profileImage'] ?? targetAvatar;
            }
          }

          // Determine Target for Passenger Reports on Company Trips
          String targetId = trip.driverId;
          String targetType = 'driver';

          if (trip.isCompany) {
            bool shouldReportDriver =
                booking.status == 'confirmed' ||
                booking.status == 'completed' ||
                booking.paymentStatus == 'paid';

            if (!shouldReportDriver) {
              targetId = trip.companyId ?? trip.driverId;
              targetType = 'company';
            }
          }

          interactions.add({
            'bookingId': booking.id,
            'tripId': trip.id,
            'driverId': trip.driverId,
            'companyId': trip.companyId,
            'targetId': targetId,
            'targetType': targetType,
            'targetName': targetName,
            'targetAvatar': targetAvatar,
            'title':
                '${trip.isCompany ? 'شركة: $targetName' : 'كابتن: $targetName'} (رحلة: ${trip.departureCity} - ${trip.arrivalCity})',
            'departureCity': trip.departureCity,
            'arrivalCity': trip.arrivalCity,
            'bookingStatus': booking.status,
            'paymentStatus': booking.paymentStatus,
            'bookingTime': booking.bookingTime,
          });
        }
      } catch (e) {
        debugPrint('Error loading trip for interaction: $e');
      }
    }

    return interactions;
  }

  @override
  Future<List<Map<String, dynamic>>> getDriverRecentBookingInteractions(
    String driverId,
  ) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('bookingTime', descending: true)
        .limit(20)
        .get();

    final interactions = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final booking = Booking.fromJson(doc.data()..['id'] = doc.id);

      try {
        final passengerDoc = await _firestore
            .collection('passengers')
            .doc(booking.passengerId)
            .get();
        String passengerName = booking.name;
        String passengerAvatar = '';

        if (passengerDoc.exists && passengerDoc.data() != null) {
          passengerName = passengerDoc.data()!['fullName'] ?? passengerName;
          passengerAvatar = passengerDoc.data()!['profileImage'] ?? '';
        }

        interactions.add({
          'bookingId': booking.id,
          'tripId': booking.tripId,
          'passengerId': booking.passengerId,
          'targetId': booking.passengerId,
          'targetType': 'passenger',
          'targetName': passengerName,
          'targetAvatar': passengerAvatar,
          'title': 'راكب: $passengerName',
          'bookingStatus': booking.status,
          'paymentStatus': booking.paymentStatus,
          'bookingTime': booking.bookingTime,
        });
      } catch (e) {
        debugPrint('Error loading passenger for interaction: $e');
      }
    }

    return interactions;
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanyRecentBookingInteractions(
    String companyId,
  ) async {
    final tripsSnapshot = await _firestore
        .collection('trips')
        .where('companyId', isEqualTo: companyId)
        .orderBy('departureTime', descending: true)
        .limit(10)
        .get();

    final interactions = <Map<String, dynamic>>[];

    for (var doc in tripsSnapshot.docs) {
      final trip = Trip.fromJson(doc.data()..['id'] = doc.id);

      if (trip.driverId.isNotEmpty) {
        String driverName = trip.driverName;
        String driverAvatar = trip.driverAvatar;

        try {
          final driverDoc = await _firestore
              .collection('drivers')
              .doc(trip.driverId)
              .get();
          if (driverDoc.exists && driverDoc.data() != null) {
            driverName = driverDoc.data()!['fullName'] ?? driverName;
            driverAvatar = driverDoc.data()!['profileImage'] ?? driverAvatar;
          }
        } catch (_) {}

        interactions.add({
          'bookingId': '',
          'tripId': trip.id,
          'driverId': trip.driverId,
          'targetId': trip.driverId,
          'targetType': 'driver',
          'targetName': driverName,
          'targetAvatar': driverAvatar,
          'title':
              'كابتن: $driverName (رحلة: ${trip.departureCity} - ${trip.arrivalCity})',
          'departureCity': trip.departureCity,
          'arrivalCity': trip.arrivalCity,
          'bookingStatus': trip.status,
          'paymentStatus': '',
          'bookingTime': trip.departureTime,
        });
      }

      try {
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('tripId', isEqualTo: trip.id)
            .limit(5)
            .get();

        for (var bDoc in bookingsSnapshot.docs) {
          final booking = Booking.fromJson(bDoc.data()..['id'] = bDoc.id);

          String passengerName = booking.name;
          String passengerAvatar = '';

          try {
            final passengerDoc = await _firestore
                .collection('passengers')
                .doc(booking.passengerId)
                .get();
            if (passengerDoc.exists && passengerDoc.data() != null) {
              passengerName = passengerDoc.data()!['fullName'] ?? passengerName;
              passengerAvatar = passengerDoc.data()!['profileImage'] ?? '';
            }
          } catch (_) {}

          interactions.add({
            'bookingId': booking.id,
            'tripId': trip.id,
            'passengerId': booking.passengerId,
            'targetId': booking.passengerId,
            'targetType': 'passenger',
            'targetName': passengerName,
            'targetAvatar': passengerAvatar,
            'title':
                'راكب: $passengerName (رحلة: ${trip.departureCity} - ${trip.arrivalCity})',
            'bookingStatus': booking.status,
            'paymentStatus': booking.paymentStatus,
            'bookingTime': booking.bookingTime,
          });
        }
      } catch (e) {
        debugPrint('Error getting bookings for company trip: $e');
      }
    }

    interactions.sort((a, b) {
      DateTime timeA = a['bookingTime'] as DateTime;
      DateTime timeB = b['bookingTime'] as DateTime;
      return timeB.compareTo(timeA);
    });

    return interactions;
  }

  @override
  Stream<List<Trip>> watchTrips() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _firestore
        .collection('trips')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          final trips = <Trip>[];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              final trip = Trip.fromJson(data);
              // Filter out trips that are in the past
              if (!trip.departureTime.isBefore(today)) {
                trips.add(trip);
              }
            } catch (e) {
              debugPrint('Error parsing trip stream: $e');
            }
          }
          return trips;
        });
  }

  @override
  Future<List<Trip>> searchTrips({
    required String departureCountryId,
    required String departureProvinceId,
    required String departureCityId,
    required String arrivalCountryId,
    required String arrivalProvinceId,
    required String arrivalCityId,
    int passengerCount = 1,
    String? tripType,
    DateTime? travelDate,
  }) async {
    try {
      // ====================
      // STEP 1: Build Firestore query and print every clause
      // ====================
      debugPrint('====================');
      debugPrint('STEP 1');
      debugPrint('Building Firestore query...');
      Query<Map<String, dynamic>> query = _firestore.collection('trips');
      debugPrint('where status == published');
      query = query.where('status', isEqualTo: 'published');

      if (departureCountryId.isNotEmpty) {
        debugPrint('where departureCountryId == $departureCountryId');
        query = query.where(
          'departureCountryId',
          isEqualTo: departureCountryId.trim().toLowerCase(),
        );
      }
      if (departureProvinceId.isNotEmpty) {
        debugPrint('where departureProvinceId == $departureProvinceId');
        query = query.where(
          'departureProvinceId',
          isEqualTo: departureProvinceId.trim().toLowerCase(),
        );
      }
      if (departureCityId.isNotEmpty) {
        debugPrint('where departureCityId == $departureCityId');
        query = query.where(
          'departureCityId',
          isEqualTo: departureCityId.trim().toLowerCase(),
        );
      }
      if (arrivalCountryId.isNotEmpty) {
        debugPrint('where arrivalCountryId == $arrivalCountryId');
        query = query.where(
          'arrivalCountryId',
          isEqualTo: arrivalCountryId.trim().toLowerCase(),
        );
      }
      if (arrivalProvinceId.isNotEmpty) {
        debugPrint('where arrivalProvinceId == $arrivalProvinceId');
        query = query.where(
          'arrivalProvinceId',
          isEqualTo: arrivalProvinceId.trim().toLowerCase(),
        );
      }
      if (arrivalCityId.isNotEmpty) {
        debugPrint('where arrivalCityId == $arrivalCityId');
        query = query.where(
          'arrivalCityId',
          isEqualTo: arrivalCityId.trim().toLowerCase(),
        );
      }
      if (passengerCount > 1) {
        debugPrint('where remainingSeats >= $passengerCount');
        query = query.where(
          'remainingSeats',
          isGreaterThanOrEqualTo: passengerCount,
        );
      }
      if (tripType != null && tripType.isNotEmpty) {
        debugPrint('where tripType == $tripType');
        query = query.where('tripType', isEqualTo: tripType);
      }
      if (travelDate != null) {
        final start = Timestamp.fromDate(
          DateTime(travelDate.year, travelDate.month, travelDate.day),
        );
        final end = Timestamp.fromDate(
          DateTime(
            travelDate.year,
            travelDate.month,
            travelDate.day,
          ).add(const Duration(days: 1)),
        );
        debugPrint('where departureTime >= $start && < $end');
        query = query.where(
          'departureTime',
          isGreaterThanOrEqualTo: start,
          isLessThan: end,
        );
      }
      debugPrint('limit 100');
      query = query.limit(100);

      // ====================
      // STEP 2: Execute query and list document ids
      // ====================
      final snapshot = await query.get();
      debugPrint('STEP 2');
      debugPrint('Firestore returned: ${snapshot.docs.length} documents');
      if (snapshot.docs.isEmpty) {
        debugPrint('STOP: No documents matched the query.');
        return [];
      }
      for (var doc in snapshot.docs) {
        debugPrint('Document ID: ${doc.id}');
      }

      // ====================
      // STEP 3 & 4: Evaluate each document and print rejection reasons
      // ====================
      List<Trip> valid = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final trip = Trip.fromJson(data);

          // STEP 3: Print required fields
          debugPrint('--- Document ${doc.id} fields ---');
          debugPrint('status: ${trip.status}');
          debugPrint('tripType: ${trip.tripType}');
          debugPrint('departureCountryId: ${trip.departureCountryId}');
          debugPrint('departureProvinceId: ${trip.departureProvinceId}');
          debugPrint('departureCityId: ${trip.departureCityId}');
          debugPrint('arrivalCountryId: ${trip.arrivalCountryId}');
          debugPrint('arrivalProvinceId: ${trip.arrivalProvinceId}');
          debugPrint('arrivalCityId: ${trip.arrivalCityId}');
          debugPrint('remainingSeats: ${trip.remainingSeats}');
          debugPrint('departureTime: ${trip.departureTime}');

          // STEP 4: Validation with explicit REJECTED logging
          if (trip.status != 'published') {
            debugPrint('REJECTED');
            debugPrint('Reason: status != published');
            debugPrint('Expected: published');
            debugPrint('Actual: ${trip.status}');
            continue;
          }
          if (departureCountryId.isNotEmpty &&
              trip.departureCountryId.trim().toLowerCase() !=
                  departureCountryId.trim().toLowerCase()) {
            debugPrint('REJECTED');
            debugPrint('Reason: departureCountryId mismatch');
            debugPrint('Expected: $departureCountryId');
            debugPrint('Actual: ${trip.departureCountryId}');
            continue;
          }
          if (departureProvinceId.isNotEmpty &&
              trip.departureProvinceId.trim().toLowerCase() !=
                  departureProvinceId.trim().toLowerCase()) {
            debugPrint('REJECTED');
            debugPrint('Reason: departureProvinceId mismatch');
            debugPrint('Expected: $departureProvinceId');
            debugPrint('Actual: ${trip.departureProvinceId}');
            continue;
          }
          if (departureCityId.isNotEmpty &&
              trip.departureCityId.trim().toLowerCase() !=
                  departureCityId.trim().toLowerCase()) {
            debugPrint('REJECTED');
            debugPrint('Reason: departureCityId mismatch');
            debugPrint('Expected: $departureCityId');
            debugPrint('Actual: ${trip.departureCityId}');
            continue;
          }
          if (arrivalCountryId.isNotEmpty &&
              trip.arrivalCountryId.trim().toLowerCase() !=
                  arrivalCountryId.trim().toLowerCase()) {
            debugPrint('REJECTED');
            debugPrint('Reason: arrivalCountryId mismatch');
            debugPrint('Expected: $arrivalCountryId');
            debugPrint('Actual: ${trip.arrivalCountryId}');
            continue;
          }
          if (arrivalProvinceId.isNotEmpty &&
              trip.arrivalProvinceId.trim().toLowerCase() !=
                  arrivalProvinceId.trim().toLowerCase()) {
            debugPrint('REJECTED');
            debugPrint('Reason: arrivalProvinceId mismatch');
            debugPrint('Expected: $arrivalProvinceId');
            debugPrint('Actual: ${trip.arrivalProvinceId}');
            continue;
          }
          if (arrivalCityId.isNotEmpty &&
              trip.arrivalCityId.trim().toLowerCase() !=
                  arrivalCityId.trim().toLowerCase()) {
            debugPrint('REJECTED');
            debugPrint('Reason: arrivalCityId mismatch');
            debugPrint('Expected: $arrivalCityId');
            debugPrint('Actual: ${trip.arrivalCityId}');
            continue;
          }
          if (trip.remainingSeats < passengerCount) {
            debugPrint('REJECTED');
            debugPrint('Reason: not enough seats');
            debugPrint('Expected at least: $passengerCount');
            debugPrint('Actual: ${trip.remainingSeats}');
            continue;
          }
          if (tripType != null &&
              tripType.isNotEmpty &&
              trip.tripType != tripType) {
            debugPrint('REJECTED');
            debugPrint('Reason: tripType mismatch');
            debugPrint('Expected: $tripType');
            debugPrint('Actual: ${trip.tripType}');
            continue;
          }
          if (travelDate != null) {
            final startOfDay = DateTime(
              travelDate.year,
              travelDate.month,
              travelDate.day,
            );
            final endOfDay = startOfDay.add(const Duration(days: 1));
            if (trip.departureTime.isBefore(startOfDay) ||
                trip.departureTime.isAfter(endOfDay)) {
              debugPrint('REJECTED');
              debugPrint('Reason: travelDate out of range');
              debugPrint('Expected day: $travelDate');
              debugPrint('Actual: ${trip.departureTime}');
              continue;
            }
          }

          // Accepted trip
          valid.add(trip);
        } catch (e) {
          debugPrint('Mapping Exception for doc ${doc.id}: $e');
        }
      }

      if (valid.isEmpty) {
        debugPrint('STOP: All retrieved documents were rejected.');
        return [];
      }

      debugPrint('Filtered ${valid.length} trips after validation');
      valid.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return valid;
    } catch (e) {
      debugPrint('searchTrips Exception: $e');
      return [];
    }
  }

  @override
  Future<List<Trip>> getNearbyTrips() async {
    try {
      debugPrint('Fetching nearby trips...');
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'published')
          .get();

      debugPrint('Found ${snapshot.docs.length} active trips in Firestore.');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final trips = <Trip>[];
      int parseErrors = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          trips.add(Trip.fromJson(data));
        } catch (e, stack) {
          parseErrors++;
          debugPrint('Failed to parse trip ${doc.id}: $e\n$stack');
        }
      }

      debugPrint(
        'Parsed ${trips.length} trips successfully. $parseErrors parsing errors.',
      );

      final filteredTrips = <Trip>[];
      int dateMismatch = 0;
      int seatsMismatch = 0;

      for (var trip in trips) {
        final hasSeats = trip.remainingSeats > 0;
        final isFuture =
            trip.departureTime.isAfter(today) ||
            trip.departureTime.isAtSameMomentAs(today);

        if (!hasSeats) {
          seatsMismatch++;
        } else if (!isFuture) {
          dateMismatch++;
        } else {
          filteredTrips.add(trip);
        }
      }

      debugPrint(
        'getNearbyTrips Summary: Total parsed: ${trips.length}. Valid: ${filteredTrips.length}. Seats mismatch: $seatsMismatch. Date mismatch: $dateMismatch.',
      );

      filteredTrips.sort((a, b) => a.departureTime.compareTo(b.departureTime));

      return filteredTrips.take(10).toList();
    } catch (e, stack) {
      debugPrint('Error fetching nearby trips: $e\n$stack');
      return [];
    }
  }

  @override
  Future<List<Trip>> getSuggestedTrips() async {
    return searchTrips(
      departureCountryId: '',
      departureProvinceId: '',
      departureCityId: '',
      arrivalCountryId: '',
      arrivalProvinceId: '',
      arrivalCityId: '',
    );
  }

  @override
  Stream<Booking?> watchBooking(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }
      return null;
    });
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    final bookingDoc = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      // READ ALL
      final bookingSnapshot = await transaction.get(bookingDoc);
      if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
        return;
      }

      final booking = Booking.fromJson(bookingSnapshot.data()!);
      if ([
        'cancelled',
        'rejected',
        'payment_not_received',
        'expired',
        'cancelled_by_passenger',
        'cancelled_by_driver',
      ].contains(booking.status)) {
        return; // Already released or invalid state for cancellation
      }

      final tripDoc = _firestore.collection('trips').doc(booking.tripId);
      final tripSnap = await transaction.get(tripDoc);
      if (!tripSnap.exists || tripSnap.data() == null) {
        return;
      }
      final trip = Trip.fromJson(tripSnap.data()!);

      // COMPUTE UPDATES
      final newRemaining = (trip.remainingSeats + booking.seatNumbers.length)
          .clamp(0, trip.totalSeats);
      final updatedLayout = trip.seatLayout.map((seat) {
        if (booking.seatNumbers.contains(seat.number)) {
          return seat.copyWith(status: 'available');
        }
        return seat;
      }).toList();

      // WRITE ALL
      transaction.update(tripDoc, {
        'remainingSeats': newRemaining,
        'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
      });

      transaction.update(bookingDoc, {'status': 'cancelled'});
    });

    // Notify Driver
    final booking = await getBooking(bookingId);
    if (booking != null) {
      await SystemNotificationService.sendNotification(
        title: 'تم إلغاء الحجز',
        body: 'قام الراكب بإلغاء حجزه في رحلتك.',
        targetUserId: booking.driverId,
        category: 'booking',
        targetRole: 'driver',
      );
    }
  }

  @override
  Future<void> updateBookingAttendance(
    String bookingId,
    String attendance,
  ) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'attendanceStatus': attendance,
    });
  }

  @override
  Future<void> updateTripStops(String tripId, List<Stop> stops) async {
    await _firestore.collection('trips').doc(tripId).update({
      'stops': stops.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<void> updateTripSeats(String tripId, List<Seat> seats) async {
    await _firestore.collection('trips').doc(tripId).update({
      'seatLayout': seats.map((e) => e.toJson()).toList(),
    });
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });

    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (doc.exists && doc.data() != null) {
      final booking = Booking.fromJson(doc.data()!);

      String title = 'تحديث الحجز';
      String body = 'قام السائق بتغيير حالة الحجز.';

      if (status == 'confirmed' || status == 'accepted') {
        title = 'تم تأكيد حجزك';
        body = 'قام السائق بتأكيد حجزك.';
      } else if (status == 'cancelled' || status == 'rejected') {
        title = 'تم رفض الحجز';
        body = 'عذراً، قام السائق برفض حجزك.';
      }

      await SystemNotificationService.sendNotification(
        title: title,
        body: body,
        targetUserId: booking.passengerId,
        category: 'booking',
        targetRole: 'passenger',
      );
    }
  }

  @override
  Future<void> addTripReview({
    required String tripId,
    required String driverId,
    required String passengerId,
    required double rating,
    required String comment,
    required Map<String, dynamic> reviewCategories,
    String? bookingId,
  }) async {
    // 1. Verify passenger authentication
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != passengerId) {
      throw Exception('Unauthorized: Only authenticated passenger can submit a review');
    }

    // 2. Resolve booking if not directly provided
    String resolvedBookingId = bookingId ?? '';
    if (resolvedBookingId.isEmpty) {
      final bookingSnap = await _firestore
          .collection('bookings')
          .where('tripId', isEqualTo: tripId)
          .where('passengerId', isEqualTo: passengerId)
          .limit(1)
          .get();
      if (bookingSnap.docs.isNotEmpty) {
        resolvedBookingId = bookingSnap.docs.first.id;
      }
    }

    if (resolvedBookingId.isEmpty) {
      throw Exception('Booking not found for this passenger and trip');
    }

    final bookingRef = _firestore.collection('bookings').doc(resolvedBookingId);
    final tripRef = _firestore.collection('trips').doc(tripId);
    final reviewDocId = '${resolvedBookingId}_$passengerId';
    final reviewRef = _firestore.collection('reviews').doc(reviewDocId);
    final driverRef = _firestore.collection('drivers').doc(driverId);

    await _firestore.runTransaction((transaction) async {
      // Check existing review (idempotency)
      final reviewSnap = await transaction.get(reviewRef);
      if (reviewSnap.exists) {
        throw Exception('تم تقييم هذه الرحلة مسبقاً');
      }

      // Check booking eligibility
      final bookingDoc = await transaction.get(bookingRef);
      if (!bookingDoc.exists) {
        throw Exception('الحجز غير موجود');
      }
      final bookingData = bookingDoc.data()!;
      if (bookingData['passengerId'] != passengerId) {
        throw Exception('غير مصرح لك بتقييم هذا الحجز');
      }
      final bookingStatus =
          (bookingData['status'] as String? ?? '').toLowerCase();
      if (bookingStatus != 'completed') {
        throw Exception('لا يمكن تقييم الرحلة إلا بعد اكتمالها');
      }

      // Check trip status
      final tripDoc = await transaction.get(tripRef);
      if (tripDoc.exists) {
        final tripStatus =
            (tripDoc.data()?['status'] as String? ?? '').toLowerCase();
        if (tripStatus != 'completed') {
          throw Exception('الرحلة لم تكتمل بعد');
        }
      }

      // Check driver document and recalculate driverRating
      final driverDoc = await transaction.get(driverRef);
      int oldCount = 0;
      double oldSum = 0.0;

      if (driverDoc.exists && driverDoc.data() != null) {
        final driverData = driverDoc.data()!;
        oldCount = (driverData['ratingCount'] as num?)?.toInt() ?? 0;
        oldSum = (driverData['ratingSum'] as num?)?.toDouble() ?? 0.0;
        // Fallback for legacy records that had rating but no count
        if (oldCount == 0 &&
            driverData['rating'] != null &&
            (driverData['rating'] as num) > 0) {
          oldCount = 1;
          oldSum = (driverData['rating'] as num).toDouble();
        }
      }

      final int newCount = oldCount + 1;
      final double newSum = oldSum + rating;
      final double newRating =
          double.parse((newSum / newCount).toStringAsFixed(2));

      // 1. Create review doc with deterministic ID
      transaction.set(reviewRef, {
        'id': reviewDocId,
        'bookingId': resolvedBookingId,
        'tripId': tripId,
        'driverId': driverId,
        'passengerId': passengerId,
        'rating': rating,
        'comment': comment,
        'categories': reviewCategories,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update booking document
      transaction.update(bookingRef, {
        'isRated': true,
        'rating': rating,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update driver rating in drivers collection
      if (driverDoc.exists) {
        transaction.update(driverRef, {
          'driverRating': newRating,
          'rating': newRating,
          'ratingCount': newCount,
          'ratingSum': newSum,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(
          driverRef,
          {
            'id': driverId,
            'driverRating': newRating,
            'rating': newRating,
            'ratingCount': newCount,
            'ratingSum': newSum,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  @override
  Future<Booking?> getBooking(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (doc.exists && doc.data() != null) {
      return Booking.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> createBookingRequest(Booking booking) async {
    // 1. Fetch active bookings (outside transaction due to Firestore limits on queries in transactions)
    final activeBookingsQuery = await _firestore
        .collection('bookings')
        .where('tripId', isEqualTo: booking.tripId)
        .where(
          'status',
          whereIn: ['pending_payment', 'payment_verification', 'confirmed'],
        )
        .get();

    final reservedSeats = <String>{};
    for (var doc in activeBookingsQuery.docs) {
      final b = Booking.fromJson(doc.data());
      reservedSeats.addAll(b.seatNumbers);
    }

    final requestedSeats = booking.seatNumbers;
    // 2. Fast fail if requested seat is already taken in the pre-check
    for (var seatNumber in requestedSeats) {
      if (reservedSeats.contains(seatNumber)) {
        throw Exception('أحد المقاعد التي اخترتها لم يعد متاحًا.');
      }
    }

    final tripDoc = _firestore.collection('trips').doc(booking.tripId);

    await _firestore.runTransaction((transaction) async {
      // 3. Read the Trip
      final snapshot = await transaction.get(tripDoc);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('الرحلة غير موجودة.');
      }
      final trip = Trip.fromJson(snapshot.data()!);

      // Strict validation: Reject booking if trip has already departed or is not in bookable state
      final now = DateTime.now();
      if (trip.departureTime.isBefore(now)) {
        throw Exception('عذراً، انطلق موعد هذه الرحلة بالفعل ولم يعد الحجز متاحاً.');
      }

      final bookableStatuses = ['open', 'published', 'active', 'upcoming', 'scheduled'];
      if (!bookableStatuses.contains(trip.status.toLowerCase())) {
        throw Exception('عذراً، هذه الرحلة غير متاحة للحجز حالياً.');
      }

      // We strictly ensure the booking inherits the canonical driverId from the trip.
      // This protects against clients sending an arbitrary driverId.
      final authoritativeBooking = booking.copyWith(driverId: trip.driverId);

      // 4. Verify requested seats exist and are valid
      for (var seatNumber in requestedSeats) {
        final seatExists = trip.seatLayout.any((s) => s.number == seatNumber);
        if (!seatExists) {
          throw Exception('المقعد $seatNumber غير موجود في هذه الرحلة.');
        }
        final seatDef = trip.seatLayout.firstWhere(
          (s) => s.number == seatNumber,
        );
        if (seatDef.status == 'driver') {
          throw Exception('لا يمكن حجز مقعد السائق.');
        }
        if (seatDef.status == 'blocked') {
          throw Exception('المقعد $seatNumber مغلق.');
        }
      }

      // 5. Verify enough remaining seats exist atomically
      if (trip.remainingSeats < requestedSeats.length) {
        throw Exception('لا توجد مقاعد كافية متاحة.');
      }

      // 10. Update remainingSeats and seat status
      final newRemaining = trip.remainingSeats - requestedSeats.length;
      final updatedLayout = trip.seatLayout.map((seat) {
        if (requestedSeats.contains(seat.number)) {
          return seat.copyWith(status: 'temporarily_reserved');
        }
        return seat;
      }).toList();
      transaction.update(tripDoc, {
        'remainingSeats': newRemaining,
        'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
      });

      // 9. Create the booking
      final bookingDoc = _firestore
          .collection('bookings')
          .doc(authoritativeBooking.id);
      transaction.set(bookingDoc, authoritativeBooking.toJson());
    });

    // PART 2 & 12 — VERIFY THE ACTUAL FIRESTORE BOOKING
    final bookingSnapshot = await _firestore
        .collection('bookings')
        .doc(booking.id)
        .get();
    if (!bookingSnapshot.exists) {
      debugPrint('BUG: Booking document was not created!');
    } else {
      final bData = bookingSnapshot.data()!;
      debugPrint('[BOOKING_CREATE_DEBUG]');
      debugPrint('bookingDocumentId: ${bookingSnapshot.id}');
      debugPrint('booking.id: ${bData['id']}');
      debugPrint('tripId: ${bData['tripId']}');
      debugPrint('passengerId: ${bData['passengerId']}');
      debugPrint('driverId: ${bData['driverId']}');
      debugPrint('status: ${bData['status']}');
      debugPrint('paymentStatus: ${bData['paymentStatus']}');
      debugPrint('seatNumber: ${bData['seatNumber']}');
      debugPrint('seatNumbers: ${bData['seatNumbers']}');
      debugPrint('createdAt: ${bData['createdAt']}');

      final authState = _ref.read(authProvider);
      if (authState is Authenticated) {
        debugPrint('authState.user.id: ${authState.user.id}');
        debugPrint('authState.user.uid: ${authState.user.uid}');
      }

      final tripSnap = await _firestore
          .collection('trips')
          .doc(booking.tripId)
          .get();
      if (tripSnap.exists) {
        final tData = tripSnap.data()!;
        debugPrint('trip.id: ${tripSnap.id}');
        debugPrint('trip.driverId: ${tData['driverId']}');
        debugPrint('trip.remainingSeats: ${tData['remainingSeats']}');
      }
    }

    await SystemNotificationService.sendNotification(
      title: 'طلب حجز جديد',
      body:
          '${booking.name} يريد حجز المقاعد: ${booking.seatNumbers.join("، ")}',
      targetUserId: booking.driverId,
      category: 'booking',
      targetRole: 'driver',
    );
  }

  @override
  Future<void> submitPaymentProof(
    String bookingId,
    String proofUrl,
    String transactionReference,
    String senderName,
    double amount,
    String? paymentMethodId,
  ) async {
    debugPrint(
      '[PAYMENT_PROOF] starting firestore update for booking $bookingId',
    );
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'payment_verification',
      'paymentStatus': 'pending_driver_verification',
      'paymentProofUrl': proofUrl,
      'transactionReference': transactionReference,
      'senderName': senderName,
      'transferAmount': amount,
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      'transferSubmittedAt': DateTime.now().toIso8601String(),
    });
    debugPrint('[PAYMENT_PROOF] booking update completed');

    // Make notification a fire-and-forget best-effort task so it doesn't block the UI
    debugPrint('[PAYMENT_PROOF] launching detached notification task');
    _sendPaymentProofNotification(bookingId);
  }

  Future<void> _sendPaymentProofNotification(String bookingId) async {
    try {
      debugPrint('[PAYMENT_PROOF] loading booking for notification');
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      debugPrint('[PAYMENT_PROOF] booking loaded');
      if (bookingDoc.exists) {
        final booking = Booking.fromJson(bookingDoc.data()!);
        debugPrint('[PAYMENT_PROOF] sending driver notification');
        await SystemNotificationService.sendNotification(
          title: 'إثبات تحويل جديد',
          body: 'قام ${booking.name} بإرسال إثبات التحويل لمبلغ التأكيد.',
          targetUserId: booking.driverId,
          category: 'payment',
          targetRole: 'driver',
        ).timeout(const Duration(seconds: 15));
        debugPrint('[PAYMENT_PROOF] notification completed');
      }
    } catch (e) {
      debugPrint('[PAYMENT_PROOF] Notification failed: $e');
    }
  }

  @override
  Future<void> confirmBookingDeposit(String bookingId, String driverId) async {
    final bookingDoc = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      // READ ALL
      final snapshot = await transaction.get(bookingDoc);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('الحجز غير موجود.');
      }

      final booking = Booking.fromJson(snapshot.data()!);
      if (booking.driverId != driverId) {
        throw Exception('غير مصرح لك بتأكيد هذا الحجز.');
      }
      if (booking.status != 'payment_verification') {
        throw Exception('حالة الحجز الحالية لا تسمح بالتأكيد.');
      }

      final tripDoc = _firestore.collection('trips').doc(booking.tripId);
      final tripSnap = await transaction.get(tripDoc);
      if (!tripSnap.exists || tripSnap.data() == null) {
        throw Exception('الرحلة غير موجودة.');
      }
      final trip = Trip.fromJson(tripSnap.data()!);

      // COMPUTE UPDATES
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final suffix = random.substring(random.length - 6);
      final bookingNumber = 'RH-${DateTime.now().year}-$suffix';

      final updatedLayout = trip.seatLayout.map((seat) {
        if (booking.seatNumbers.contains(seat.number)) {
          return seat.copyWith(status: 'booked');
        }
        return seat;
      }).toList();

      // WRITE ALL
      transaction.update(tripDoc, {
        'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
      });

      transaction.update(bookingDoc, {
        'status': 'confirmed',
        'paymentStatus': 'received',
        'depositConfirmed': true,
        'paymentVerifiedAt': DateTime.now().toIso8601String(),
        'paymentVerifiedBy': driverId,
        'bookingNumber': bookingNumber,
      });
    });

    final booking = await getBooking(bookingId);
    if (booking != null) {
      await SystemNotificationService.sendNotification(
        title: '🎉 تم تأكيد حجزك بنجاح',
        body: 'قام السائق بتأكيد استلام مبلغ الحجز.',
        targetUserId: booking.passengerId,
        category: 'booking',
        targetRole: 'passenger',
      );
    }
  }

  @override
  Future<void> rejectPaymentVerification(
    String bookingId,
    String driverId,
    String reason,
  ) async {
    final bookingDoc = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      // READ ALL
      final snapshot = await transaction.get(bookingDoc);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('الحجز غير موجود.');
      }

      final booking = Booking.fromJson(snapshot.data()!);
      if (booking.driverId != driverId) {
        throw Exception('غير مصرح لك برفض هذا الحجز.');
      }

      if (booking.status != 'payment_verification') {
        throw Exception('حالة الحجز الحالية لا تسمح بالرفض.');
      }

      final tripDoc = _firestore.collection('trips').doc(booking.tripId);
      final tripSnap = await transaction.get(tripDoc);
      if (!tripSnap.exists || tripSnap.data() == null) {
        throw Exception('الرحلة غير موجودة.');
      }
      final trip = Trip.fromJson(tripSnap.data()!);

      // COMPUTE UPDATES
      final newSeats = (trip.remainingSeats + booking.seatNumbers.length).clamp(
        0,
        trip.totalSeats,
      );
      final updatedLayout = trip.seatLayout.map((seat) {
        if (booking.seatNumbers.contains(seat.number)) {
          return seat.copyWith(status: 'available');
        }
        return seat;
      }).toList();

      // WRITE ALL
      transaction.update(tripDoc, {
        'remainingSeats': newSeats,
        'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
      });

      transaction.update(bookingDoc, {
        'status':
            'payment_not_received', // Explicitly reject and clear reservation
        'paymentStatus': 'not_received',
        'paymentRejectionReason': reason,
        'paymentRejectedAt': DateTime.now().toIso8601String(),
        'paymentRejectedBy': driverId,
      });
    });

    final booking = await getBooking(bookingId);
    if (booking != null) {
      await SystemNotificationService.sendNotification(
        title: 'لم يتم استلام مبلغ التأكيد',
        body:
            'أفاد السائق بأن مبلغ التأكيد لم يصل إليه. يمكنك مراجعة العملية أو التواصل مع الدعم.',
        targetUserId: booking.passengerId,
        category: 'payment',
        targetRole: 'passenger',
      );
    }
  }

  @override
  Future<void> expireBooking(String bookingId) async {
    final bookingDoc = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      // READ ALL
      final snapshot = await transaction.get(bookingDoc);
      if (!snapshot.exists || snapshot.data() == null) {
        return;
      }

      final booking = Booking.fromJson(snapshot.data()!);
      if (booking.status == 'pending_payment') {
        final tripDoc = _firestore.collection('trips').doc(booking.tripId);
        final tripSnap = await transaction.get(tripDoc);

        if (tripSnap.exists && tripSnap.data() != null) {
          final trip = Trip.fromJson(tripSnap.data()!);

          // COMPUTE UPDATES
          final newSeats = (trip.remainingSeats + booking.seatNumbers.length)
              .clamp(0, trip.totalSeats);
          final updatedLayout = trip.seatLayout.map((seat) {
            if (booking.seatNumbers.contains(seat.number)) {
              return seat.copyWith(status: 'available');
            }
            return seat;
          }).toList();

          // WRITE ALL
          transaction.update(tripDoc, {
            'remainingSeats': newSeats,
            'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
          });
        }

        transaction.update(bookingDoc, {
          'status': 'expired',
          'paymentStatus': 'not_submitted',
        });
      }
    });

    final booking = await getBooking(bookingId);
    if (booking != null && booking.status == 'expired') {
      await SystemNotificationService.sendNotification(
        title: 'انتهت مهلة تأكيد الحجز',
        body: 'تم إلغاء الحجز لعدم استلام إثبات التحويل في الوقت المحدد.',
        targetUserId: booking.passengerId,
        category: 'booking',
        targetRole: 'passenger',
      );
    }
  }

  @override
  Future<void> createManualDriverBooking(Booking booking) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('يجب تسجيل الدخول لإتمام العملية.');
    }
    if (booking.driverId != currentUserId) {
      throw Exception('طلب غير صالح.');
    }
    if (booking.bookingType != 'driver_manual') {
      throw Exception('نوع الحجز غير صالح.');
    }

    final bookingDoc = _firestore.collection('bookings').doc(booking.id);
    final tripDoc = _firestore.collection('trips').doc(booking.tripId);

    await _firestore.runTransaction((transaction) async {
      final tripSnap = await transaction.get(tripDoc);
      if (!tripSnap.exists || tripSnap.data() == null) {
        throw Exception('الرحلة غير موجودة.');
      }

      final trip = Trip.fromJson(tripSnap.data()!);

      if (trip.driverId != currentUserId) {
        throw Exception('غير مصرح لك بإدارة هذه الرحلة.');
      }

      if (trip.remainingSeats < booking.seatCount) {
        throw Exception('لا يوجد مقاعد كافية متاحة للحجز.');
      }

      final newSeats = trip.remainingSeats - booking.seatCount.toInt();
      bool seatFound = false;

      final updatedLayout = trip.seatLayout.map((seat) {
        if (booking.seatNumbers.contains(seat.number)) {
          seatFound = true;
          if (seat.status == 'blocked') {
            throw Exception('المقعد غير متاح حالياً.');
          }
          if (seat.status != 'available') {
            throw Exception('المقعد غير متاح.');
          }
          return seat.copyWith(status: 'booked');
        }
        return seat;
      }).toList();

      if (!seatFound) {
        throw Exception('المقعد المحدد لا ينتمي لهذه الرحلة.');
      }

      transaction.update(tripDoc, {
        'remainingSeats': newSeats,
        'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
      });

      transaction.set(bookingDoc, booking.toJson());
    });
  }

  @override
  Future<void> releaseManualDriverBooking(String bookingId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('يجب تسجيل الدخول لإتمام العملية.');
    }

    final bookingDoc = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingDoc);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('الحجز غير موجود.');
      }

      final booking = Booking.fromJson(snapshot.data()!);
      if (booking.bookingType != 'driver_manual') {
        throw Exception('لا يمكن تحرير إلا الحجوزات اليدوية للسائق.');
      }
      if (booking.driverId != currentUserId) {
        throw Exception('غير مصرح لك بإدارة هذا الحجز.');
      }
      if (booking.status == 'cancelled_by_driver') {
        throw Exception('تم تحرير الحجز مسبقاً.');
      }

      final tripDoc = _firestore.collection('trips').doc(booking.tripId);
      final tripSnap = await transaction.get(tripDoc);
      if (tripSnap.exists && tripSnap.data() != null) {
        final trip = Trip.fromJson(tripSnap.data()!);

        if (trip.driverId != currentUserId) {
          throw Exception('غير مصرح لك بإدارة هذه الرحلة.');
        }

        final newSeats = (trip.remainingSeats + booking.seatNumbers.length)
            .clamp(0, trip.totalSeats);
        bool seatReleased = false;

        final updatedLayout = trip.seatLayout.map((seat) {
          if (booking.seatNumbers.contains(seat.number)) {
            if (seat.status == 'booked') {
              seatReleased = true;
              return seat.copyWith(status: 'available');
            }
          }
          return seat;
        }).toList();

        if (seatReleased) {
          transaction.update(tripDoc, {
            'remainingSeats': newSeats,
            'seatLayout': updatedLayout.map((s) => s.toJson()).toList(),
          });
        }
      }

      transaction.update(bookingDoc, {'status': 'cancelled_by_driver'});
    });
  }
}
