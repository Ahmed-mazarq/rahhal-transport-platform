import 'package:flutter/foundation.dart';
import 'package:rahal/features/trips/domain/services/trip_search_service.dart';

class AppLogger {
  static void logSearch(TripSearchFilter filter, int documentsCount) {
    if (kDebugMode) {
      debugPrint('=== SEARCH EXECUTION ===');
      debugPrint('Incoming Filters:');
      debugPrint(
        ' - Departure: ${filter.departureCountry?.nameAr} -> ${filter.departureProvince?.nameAr}',
      );
      debugPrint(
        ' - Arrival: ${filter.arrivalCountry?.nameAr} -> ${filter.arrivalProvince?.nameAr}',
      );
      debugPrint(' - Passengers: ${filter.passengerCount}');
      debugPrint('Firestore Documents Retrieved: $documentsCount');
    }
  }

  static void logSearchResults(int acceptedCount) {
    if (kDebugMode) {
      debugPrint('Accepted Trips: $acceptedCount');
      debugPrint('========================');
    }
  }

  static void logRejection(String tripId, String reason) {
    if (kDebugMode) {
      debugPrint('Rejected Trip: $tripId | Reason: $reason');
    }
  }
}
