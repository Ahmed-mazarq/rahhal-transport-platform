import '../../domain/models/trip.dart';

/// Helper for displaying trip locations according to Rahhal product specification:
/// PRIMARY: Governorate / Province
/// SECONDARY: City
/// FALLBACK: Location name -> 'غير محدد'
/// Districts/neighborhoods are never shown as the primary route header.
class TripLocationDisplay {
  /// Resolves the primary origin display string
  static String getOrigin(Trip trip) {
    if (trip.departureProvince.trim().isNotEmpty) {
      return trip.departureProvince.trim();
    }
    if (trip.departureCity.trim().isNotEmpty) {
      return trip.departureCity.trim();
    }
    if (trip.startLocationName.trim().isNotEmpty) {
      return trip.startLocationName.trim();
    }
    return 'غير محدد';
  }

  /// Alias for getOrigin
  static String formatOrigin(Trip trip) => getOrigin(trip);

  /// Resolves the primary destination display string
  static String getDestination(Trip trip) {
    if (trip.arrivalProvince.trim().isNotEmpty) {
      return trip.arrivalProvince.trim();
    }
    if (trip.arrivalCity.trim().isNotEmpty) {
      return trip.arrivalCity.trim();
    }
    if (trip.endLocationName.trim().isNotEmpty) {
      return trip.endLocationName.trim();
    }
    return 'غير محدد';
  }

  /// Alias for getDestination
  static String formatDestination(Trip trip) => getDestination(trip);

  /// Formats the complete origin ⇄ destination route
  static String getRouteText(Trip trip, {String separator = ' ⇄ '}) {
    return '${getOrigin(trip)}$separator${getDestination(trip)}';
  }

  /// Formats raw location fields with province priority
  static String formatLocation({
    String? province,
    String? city,
    String? locationName,
  }) {
    if (province != null && province.trim().isNotEmpty) {
      return province.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      return city.trim();
    }
    if (locationName != null && locationName.trim().isNotEmpty) {
      return locationName.trim();
    }
    return 'غير محدد';
  }
}
