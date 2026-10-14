import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardStats {
  final int totalPassengers;
  final int totalDrivers;
  final int totalCompanies;
  final int totalVehicles;
  final int totalTrips;
  final int totalBookings;
  final int pendingDocuments;
  final int openTickets;
  final int totalReports;
  final int activeTrips;
  final int todaysTrips;
  final int onlineDrivers;
  final int activeCompanies;
  final double averageRating;
  final double platformGrowth;
  final DateTime lastUpdated;

  AdminDashboardStats({
    required this.totalPassengers,
    required this.totalDrivers,
    required this.totalCompanies,
    required this.totalVehicles,
    required this.totalTrips,
    required this.totalBookings,
    required this.pendingDocuments,
    required this.openTickets,
    required this.totalReports,
    required this.activeTrips,
    required this.todaysTrips,
    required this.onlineDrivers,
    required this.activeCompanies,
    required this.averageRating,
    required this.platformGrowth,
    required this.lastUpdated,
  });

  factory AdminDashboardStats.empty() {
    return AdminDashboardStats(
      totalPassengers: 0,
      totalDrivers: 0,
      totalCompanies: 0,
      totalVehicles: 0,
      totalTrips: 0,
      totalBookings: 0,
      pendingDocuments: 0,
      openTickets: 0,
      totalReports: 0,
      activeTrips: 0,
      todaysTrips: 0,
      onlineDrivers: 0,
      activeCompanies: 0,
      averageRating: 0.0,
      platformGrowth: 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}

class AdminDashboardRepository {
  final FirebaseFirestore _firestore;

  AdminDashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<int> _getCount(
    String collectionPath, {
    Query Function(Query query)? queryBuilder,
  }) async {
    // Let exceptions propagate
    Query query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final AggregateQuerySnapshot snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCountAcrossPrefixes(
    String collectionSuffix, {
    Query Function(Query query)? queryBuilder,
  }) async {
    int total = 0;
    for (final prefix in ['passenger', 'driver', 'company']) {
      try {
        Query query = _firestore.collection('${prefix}_$collectionSuffix');
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        final AggregateQuerySnapshot snapshot = await query.count().get();
        total += snapshot.count ?? 0;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // ignore: avoid_print
          print('Permission denied for ${prefix}_$collectionSuffix');
        }
      } catch (_) {
        // Other errors, skip
      }
    }
    return total;
  }

  Future<int> _countActiveCompanies() async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _averageRating() async {
    try {
      final AggregateQuerySnapshot snapshot = await _firestore
          .collection('drivers')
          .aggregate(average('driverRating'))
          .get();
      return snapshot.getAverage('driverRating') ?? 0.0;
    } catch (_) {
      try {
        final querySnapshot = await _firestore.collection('drivers').get();
        if (querySnapshot.docs.isEmpty) return 0.0;
        double total = 0.0;
        int validRatingsCount = 0;
        for (var doc in querySnapshot.docs) {
          final rating = doc.data()['driverRating'];
          if (rating != null && rating is num) {
            total += rating.toDouble();
            validRatingsCount++;
          }
        }
        if (validRatingsCount == 0) return 0.0;
        return total / validRatingsCount;
      } catch (_) {
        return 0.0;
      }
    }
  }

  Future<double> _monthlyGrowth() async {
    try {
      final now = DateTime.now();
      final startOfThisMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

      final thisMonthSnapshot = await _firestore
          .collection('trips')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfThisMonth),
          )
          .count()
          .get();

      final lastMonthSnapshot = await _firestore
          .collection('trips')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(startOfThisMonth))
          .count()
          .get();

      final thisMonth = thisMonthSnapshot.count ?? 0;
      final lastMonth = lastMonthSnapshot.count ?? 0;

      if (lastMonth == 0) return thisMonth > 0 ? 100.0 : 0.0;

      return ((thisMonth - lastMonth) / lastMonth) * 100.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    // Let exceptions propagate to FutureProvider to show RetryCard
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final results = await Future.wait([
      _getCount('passengers'),
      _getCount('drivers'),
      _getCount('companies'),
      _getCount('vehicles'),
      _getCount('trips'),
      _getCount('bookings'),
      _getCount(
        'driver_documents',
        queryBuilder: (q) => q.where('status', isEqualTo: 'pending'),
      ),
      _getCount(
        'vehicle_documents',
        queryBuilder: (q) => q.where('status', isEqualTo: 'pending'),
      ),
      _getCountAcrossPrefixes(
        'support_tickets',
        queryBuilder: (q) => q.where('status', isEqualTo: 'open'),
      ),
      _getCountAcrossPrefixes('support_reports'),
      _getCount(
        'trips',
        queryBuilder: (q) =>
            q.where('status', whereIn: ['running', 'active', 'started']),
      ),
      _getCount(
        'trips',
        queryBuilder: (q) => q.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
        ),
      ),
      _getCount(
        'drivers',
        queryBuilder: (q) => q.where('isOnline', isEqualTo: true),
      ),
      _countActiveCompanies(),
    ]);

    final avgRating = await _averageRating();
    final growth = await _monthlyGrowth();

    return AdminDashboardStats(
      totalPassengers: results[0],
      totalDrivers: results[1],
      totalCompanies: results[2],
      totalVehicles: results[3],
      totalTrips: results[4],
      totalBookings: results[5],
      pendingDocuments: results[6] + results[7],
      openTickets: results[8],
      totalReports: results[9],
      activeTrips: results[10],
      todaysTrips: results[11],
      onlineDrivers: results[12],
      activeCompanies: results[13],
      averageRating: avgRating,
      platformGrowth: growth,
      lastUpdated: DateTime.now(),
    );
  }
}
