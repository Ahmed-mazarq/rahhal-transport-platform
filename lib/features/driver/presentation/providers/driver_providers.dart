import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/models/trip.dart';
import '../../domain/models/driver_profile.dart';
import '../../domain/models/driver_stats.dart';
import '../../domain/models/driver_document.dart';
import '../../domain/models/driver_payment_method.dart';

final driverProfileProvider = FutureProvider<DriverProfile?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return null;

  final repo = ref.watch(driverRepositoryProvider);
  return repo.getDriverProfile(authState.user.uid);
});

final driverStatsProvider = FutureProvider<DriverStats>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return const DriverStats();

  final repo = ref.watch(driverRepositoryProvider);
  return repo.getDriverStatistics(authState.user.uid);
});

final driverAvailabilityProvider = StateProvider<bool>((ref) {
  final profileAsync = ref.watch(driverProfileProvider);
  return profileAsync.value?.isOnline ?? false;
});

final driverPerformanceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return {};

  final driverId = authState.user.uid;
  final tripRepo = ref.watch(tripRepositoryProvider);
  final fleetRepo = ref.watch(fleetRepositoryProvider);

  final trips = await tripRepo.getDriverTrips(driverId);
  final vehicles = await fleetRepo.getDriverVehicles(driverId);

  // Completion Rate
  final publishedTrips = trips.where((t) => t.status != 'draft').toList();
  final completedTrips = trips.where((t) => t.status == 'completed').toList();
  final completionRate = publishedTrips.isEmpty
      ? 1.0
      : completedTrips.length / publishedTrips.length;

  final profileAsync = ref.read(driverProfileProvider);
  final profile = profileAsync.value;

  final acceptanceRate = profile?.commitmentPercentage != null
      ? profile!.commitmentPercentage / 100.0
      : null;
  final avgResponseTime = profile?.avgResponseTimeMins;
  final uniquePassengers = profile?.totalPassengers ?? 0;
  final avgRating = profile?.rating;

  return {
    'totalTrips': trips.length,
    'completedTrips': completedTrips.length,
    'cancelledTrips': trips.where((t) => t.status == 'cancelled').length,
    'completionRate': completionRate,
    'acceptanceRate': acceptanceRate,
    'responseTime': avgResponseTime,
    'passengerCount': uniquePassengers,
    'vehicleCount': vehicles.length,
    'avgRating': avgRating,
  };
});

final driverDocumentsProvider = StreamProvider<List<DriverDocument>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('driver_documents')
      .where('driverId', isEqualTo: authState.user.uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => DriverDocument.fromJson(doc.data()))
            .toList(),
      );
});

final driverPaymentMethodsProvider = StreamProvider<List<DriverPaymentMethod>>((
  ref,
) {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return const Stream.empty();

  final repo = ref.watch(driverRepositoryProvider);
  return repo.watchDriverPaymentMethods(authState.user.uid);
});

/// Real upcoming trip for current driver (Part 9)
final driverUpcomingTripProvider = FutureProvider<Trip?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return null;

  final tripRepo = ref.watch(tripRepositoryProvider);
  final trips = await tripRepo.getDriverTrips(authState.user.uid);

  final now = DateTime.now();
  final upcoming = trips.where((t) {
    final isUpcomingState =
        t.status == 'published' ||
        t.status == 'open_for_booking' ||
        t.status == 'running' ||
        t.status == 'active';
    final isFuture = t.departureTime.isAfter(
      now.subtract(const Duration(hours: 4)),
    );
    return isUpcomingState && isFuture;
  }).toList();

  if (upcoming.isEmpty) return null;

  upcoming.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  return upcoming.first;
});

/// Real today summary metrics derived from database (Part 11)
final driverTodaySummaryProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) {
    return {
      'todayTrips': 0,
      'pendingReviews': 0,
      'confirmedPassengers': 0,
      'bookedSeats': 0,
    };
  }

  final driverId = authState.user.uid;
  final tripRepo = ref.watch(tripRepositoryProvider);
  final trips = await tripRepo.getDriverTrips(driverId);
  final bookings = await tripRepo.getDriverBookings(driverId);

  final now = DateTime.now();
  bool isToday(DateTime d) =>
      d.year == now.year && d.month == now.month && d.day == now.day;

  final todayTrips = trips.where((t) => isToday(t.departureTime)).length;

  final pendingReviews = bookings
      .where(
        (b) =>
            b.status == 'payment_verification' ||
            b.status == 'awaiting_driver_verification' ||
            b.status == 'pending' ||
            b.status == 'support_review',
      )
      .length;

  final confirmedBookingsToday = bookings.where((b) {
    final isConfirmed = b.status == 'confirmed' || b.status == 'completed';
    return isConfirmed && isToday(b.travelDate);
  }).toList();

  final confirmedPassengers = confirmedBookingsToday.length;
  final bookedSeats = confirmedBookingsToday.fold<int>(
    0,
    (acc, b) =>
        acc +
        (b.seatNumbers.isNotEmpty ? b.seatNumbers.length : b.seatCount.toInt()),
  );

  return {
    'todayTrips': todayTrips,
    'pendingReviews': pendingReviews,
    'confirmedPassengers': confirmedPassengers,
    'bookedSeats': bookedSeats,
  };
});

/// Financial summary grouped by currency (Part 14)
final driverFinancialSummaryProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return {};

  final driverId = authState.user.uid;
  final tripRepo = ref.watch(tripRepositoryProvider);
  final bookings = await tripRepo.getDriverBookings(driverId);

  final Map<String, double> totalsByCurrency = {};

  for (final b in bookings) {
    if (b.status == 'confirmed' ||
        b.status == 'completed' ||
        b.paymentStatus == 'paid') {
      final currency = b.currency.isNotEmpty ? b.currency.toUpperCase() : 'SAR';
      final amount = b.depositAmount > 0
          ? b.depositAmount
          : (b.price > 0 ? b.price : 0.0);
      totalsByCurrency[currency] = (totalsByCurrency[currency] ?? 0.0) + amount;
    }
  }

  return totalsByCurrency;
});
