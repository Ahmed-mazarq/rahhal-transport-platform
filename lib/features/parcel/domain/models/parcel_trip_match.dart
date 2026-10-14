import 'package:rahal/features/trips/domain/models/trip.dart';

class ParcelTripMatch {
  final Trip trip;
  final int score;
  final String matchType; // 'exact', 'stop', 'fallback'
  final String matchReason; // User-facing reason e.g., "مطابق للمحافظة"
  final String? pickupStopId;
  final String? dropoffStopId;
  final bool isFallback;

  ParcelTripMatch({
    required this.trip,
    required this.score,
    required this.matchType,
    required this.matchReason,
    this.pickupStopId,
    this.dropoffStopId,
    this.isFallback = false,
  });
}
