import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/admin_analytics_models.dart';

class AdminAnalyticsRepository {
  final FirebaseFirestore _firestore;

  AdminAnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withQueryContext<T>(
    String name,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Analytics query failed: $name');
        debugPrint('$e');
      }
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<int> _getCount(Query query, [String? queryName]) async {
    return _withQueryContext(queryName ?? 'count', () async {
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    });
  }

  Future<DashboardKPIs> getDashboardKPIs(AnalyticsRange range) async {
    final start = Timestamp.fromDate(range.start);
    final end = Timestamp.fromDate(range.end);

    final duration = range.end.difference(range.start);
    final prevEnd = range.start.subtract(const Duration(microseconds: 1));
    final prevStart = prevEnd.subtract(duration);

    final prevStartTs = Timestamp.fromDate(prevStart);
    final prevEndTs = Timestamp.fromDate(prevEnd);

    // 1. Platform totals (all-time) - PARALLEL
    final totalsFuture = Future.wait<int>([
      _getCount(
        _firestore.collection('passengers'),
        'analytics.totalPassengers',
      ),
      _getCount(_firestore.collection('drivers'), 'analytics.totalDrivers'),
      _getCount(_firestore.collection('companies'), 'analytics.totalCompanies'),
      _getCount(_firestore.collection('vehicles'), 'analytics.totalVehicles'),
      _getCount(_firestore.collection('trips'), 'analytics.totalTrips'),
      _getCount(_firestore.collection('bookings'), 'analytics.totalBookings'),
    ]);

    // 2. Period registration comparisons - PARALLEL
    final comparisonsFuture = Future.wait<int>([
      _getCount(
        _firestore
            .collection('passengers')
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end),
        'analytics.currentPassengers',
      ),
      _getCount(
        _firestore
            .collection('passengers')
            .where('createdAt', isGreaterThanOrEqualTo: prevStartTs)
            .where('createdAt', isLessThanOrEqualTo: prevEndTs),
        'analytics.prevPassengers',
      ),
      _getCount(
        _firestore
            .collection('drivers')
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end),
        'analytics.currentDrivers',
      ),
      _getCount(
        _firestore
            .collection('drivers')
            .where('createdAt', isGreaterThanOrEqualTo: prevStartTs)
            .where('createdAt', isLessThanOrEqualTo: prevEndTs),
        'analytics.prevDrivers',
      ),
      _getCount(
        _firestore
            .collection('companies')
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end),
        'analytics.currentCompanies',
      ),
      _getCount(
        _firestore
            .collection('companies')
            .where('createdAt', isGreaterThanOrEqualTo: prevStartTs)
            .where('createdAt', isLessThanOrEqualTo: prevEndTs),
        'analytics.prevCompanies',
      ),
    ]);

    // 3. Period trip & booking metrics - PARALLEL
    final tripsRef = _firestore.collection('trips');
    final tripsQuery = tripsRef
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end);

    final bookingsRef = _firestore.collection('bookings');
    final bookingsQuery = bookingsRef
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end);

    final tripBookingCountsFuture = Future.wait<int>([
      _getCount(tripsQuery, 'analytics.periodTrips'),
      _getCount(
        tripsQuery.where('status', isEqualTo: 'completed'),
        'analytics.completedTrips',
      ),
      _getCount(
        tripsQuery.where('status', isEqualTo: 'cancelled'),
        'analytics.cancelledTrips',
      ),
      _getCount(bookingsQuery, 'analytics.periodBookings'),
      _getCount(
        bookingsQuery.where('status', isEqualTo: 'completed'),
        'analytics.completedBookings',
      ),
      _getCount(
        bookingsQuery.where('status', isEqualTo: 'cancelled'),
        'analytics.cancelledBookings',
      ),
    ]);

    // 4. Operational stats - PARALLEL
    final operationalCountsFuture = Future.wait<int>([
      _getCount(
        _firestore.collection('drivers').where('isOnline', isEqualTo: true),
        'analytics.onlineDrivers',
      ),
      _getCount(
        _firestore
            .collection('companies')
            .where('status', whereIn: ['active', 'approved']),
        'analytics.activeCompanies',
      ),
      _getCount(
        _firestore
            .collection('driver_documents')
            .where('status', isEqualTo: 'pending'),
        'analytics.pendingDriverDocs',
      ),
      _getCount(
        _firestore
            .collection('vehicle_documents')
            .where('status', isEqualTo: 'pending'),
        'analytics.pendingVehicleDocs',
      ),
      _getCount(
        _firestore
            .collection('documents')
            .where('status', isEqualTo: 'pending'),
        'analytics.pendingOtherDocs',
      ),
      _getCount(
        _firestore
            .collection('passenger_support_tickets')
            .where('status', isEqualTo: 'open'),
        'analytics.passengerTickets',
      ),
      _getCount(
        _firestore
            .collection('driver_support_tickets')
            .where('status', isEqualTo: 'open'),
        'analytics.driverTickets',
      ),
      _getCount(
        _firestore
            .collection('company_support_tickets')
            .where('status', isEqualTo: 'open'),
        'analytics.companyTickets',
      ),
    ]);

    // 5. Occupancy/Price snapshot & Driver rating snapshot - PARALLEL
    final tripsSnapshotFuture = _withQueryContext(
      'analytics.tripsOccupancySnapshot',
      () => tripsQuery.limit(1000).get(),
    );

    final driversSnapshotFuture = _withQueryContext(
      'analytics.driverRatingSnapshot',
      () => _firestore
          .collection('drivers')
          .where('driverRating', isGreaterThan: 0)
          .limit(100)
          .get(),
    );

    // Await all groups concurrently
    final results = await Future.wait([
      totalsFuture,
      comparisonsFuture,
      tripBookingCountsFuture,
      operationalCountsFuture,
      tripsSnapshotFuture,
      driversSnapshotFuture,
    ]);

    final totals = results[0] as List<int>;
    final totalPassengers = totals[0];
    final totalDrivers = totals[1];
    final totalCompanies = totals[2];
    final totalVehicles = totals[3];
    final totalTrips = totals[4];
    final totalBookings = totals[5];

    final comparisons = results[1] as List<int>;
    final passengersChange = AnalyticsComparison(
      current: comparisons[0],
      previous: comparisons[1],
    );
    final driversChange = AnalyticsComparison(
      current: comparisons[2],
      previous: comparisons[3],
    );
    final companiesChange = AnalyticsComparison(
      current: comparisons[4],
      previous: comparisons[5],
    );

    final tripBookingCounts = results[2] as List<int>;
    final periodTrips = tripBookingCounts[0];
    final completedTrips = tripBookingCounts[1];
    final cancelledTrips = tripBookingCounts[2];
    final periodBookings = tripBookingCounts[3];
    final completedBookings = tripBookingCounts[4];
    final cancelledBookings = tripBookingCounts[5];

    final cancellationRate = periodBookings > 0
        ? (cancelledBookings / periodBookings) * 100
        : 0.0;

    final operationalCounts = results[3] as List<int>;
    final onlineDrivers = operationalCounts[0];
    final activeCompanies = operationalCounts[1];
    final pendingDriverDocs = operationalCounts[2];
    final pendingVehicleDocs = operationalCounts[3];
    final pendingOtherDocs = operationalCounts[4];
    final pendingDocuments =
        pendingDriverDocs + pendingVehicleDocs + pendingOtherDocs;

    final passengerTickets = operationalCounts[5];
    final driverTickets = operationalCounts[6];
    final companyTickets = operationalCounts[7];
    final openSupportTickets =
        passengerTickets + driverTickets + companyTickets;

    // Process Occupancy & Price
    final tripsSnapshot = results[4] as QuerySnapshot<Map<String, dynamic>>;
    double seatOccupancyRate = 0.0;
    Map<String, double> avgPrice = {};
    int totalSeatsAll = 0;
    int occupiedSeatsAll = 0;
    Map<String, List<double>> pricesByCurrency = {};

    for (var doc in tripsSnapshot.docs) {
      final data = doc.data();
      final totalSeats = data['totalSeats'] as int? ?? 0;
      final remainingSeats = data['remainingSeats'] as int? ?? totalSeats;
      if (totalSeats > 0) {
        final occupied = totalSeats - remainingSeats;
        final clampedOccupied = occupied < 0
            ? 0
            : (occupied > totalSeats ? totalSeats : occupied);
        totalSeatsAll += totalSeats;
        occupiedSeatsAll += clampedOccupied;
      }

      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final currency = data['currency'] as String? ?? 'SAR';
      if (price > 0) {
        pricesByCurrency.putIfAbsent(currency, () => []).add(price);
      }
    }

    if (totalSeatsAll > 0) {
      seatOccupancyRate = (occupiedSeatsAll / totalSeatsAll) * 100;
    }

    pricesByCurrency.forEach((currency, prices) {
      if (prices.isNotEmpty) {
        avgPrice[currency] = prices.reduce((a, b) => a + b) / prices.length;
      }
    });

    // Process Average Driver Rating
    final driversSnapshot = results[5] as QuerySnapshot<Map<String, dynamic>>;
    double averageDriverRating = 0.0;
    if (driversSnapshot.docs.isNotEmpty) {
      double sum = 0.0;
      int count = 0;
      for (var doc in driversSnapshot.docs) {
        final rating = (doc.data()['driverRating'] as num?)?.toDouble() ?? 0.0;
        if (rating > 0) {
          sum += rating;
          count++;
        }
      }
      if (count > 0) {
        averageDriverRating = sum / count;
      }
    }

    return DashboardKPIs(
      totalPassengers: totalPassengers,
      totalDrivers: totalDrivers,
      totalCompanies: totalCompanies,
      totalVehicles: totalVehicles,
      totalTrips: totalTrips,
      totalBookings: totalBookings,
      passengersChange: passengersChange,
      driversChange: driversChange,
      companiesChange: companiesChange,
      periodTrips: periodTrips,
      periodBookings: periodBookings,
      completedTrips: completedTrips,
      cancelledTrips: cancelledTrips,
      completedBookings: completedBookings,
      cancelledBookings: cancelledBookings,
      cancellationRate: cancellationRate,
      seatOccupancyRate: seatOccupancyRate,
      averageDriverRating: averageDriverRating,
      onlineDrivers: onlineDrivers,
      activeCompanies: activeCompanies,
      pendingDocuments: pendingDocuments,
      openSupportTickets: openSupportTickets,
      averageTripPriceByCurrency: avgPrice,
    );
  }

  Future<List<TopRoute>> getTopRoutes(AnalyticsRange range) async {
    final start = Timestamp.fromDate(range.start);
    final end = Timestamp.fromDate(range.end);

    final tripsRef = _firestore.collection('trips');
    final tripsQuery = tripsRef
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .limit(2000);

    final snapshot = await _withQueryContext(
      'analytics.topRoutes',
      () => tripsQuery.get(),
    );
    final routeMap = <String, TopRoute>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final startLoc = data['startLocationName'] as String? ?? '';
      final endLoc = data['endLocationName'] as String? ?? '';
      final fallbackStart = data['departureCity'] as String? ?? '';
      final fallbackEnd = data['arrivalCity'] as String? ?? '';

      final origin = startLoc.isNotEmpty
          ? startLoc
          : (fallbackStart.isNotEmpty ? fallbackStart : 'غير محدد');
      final destination = endLoc.isNotEmpty
          ? endLoc
          : (fallbackEnd.isNotEmpty ? fallbackEnd : 'غير محدد');

      final routeKey = '$origin-$destination';
      final status = data['status'] as String? ?? '';
      final completed = status == 'completed' ? 1 : 0;

      if (routeMap.containsKey(routeKey)) {
        final existing = routeMap[routeKey]!;
        routeMap[routeKey] = TopRoute(
          origin: origin,
          destination: destination,
          tripCount: existing.tripCount + 1,
          completedTrips: existing.completedTrips + completed,
        );
      } else {
        routeMap[routeKey] = TopRoute(
          origin: origin,
          destination: destination,
          tripCount: 1,
          completedTrips: completed,
        );
      }
    }

    final routes = routeMap.values.toList();
    routes.sort((a, b) => b.tripCount.compareTo(a.tripCount));

    return routes.take(5).toList();
  }
}
