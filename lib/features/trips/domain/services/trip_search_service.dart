import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/features/geo/domain/models/country.dart';
import 'package:rahal/features/geo/domain/models/governorate.dart';
import 'package:rahal/features/geo/domain/models/city.dart';

class TripSearchFilter {
  final Country? departureCountry;
  final Governorate? departureProvince;
  final City? departureCity;
  final Country? arrivalCountry;
  final Governorate? arrivalProvince;
  final City? arrivalCity;
  final DateTime? travelDate;
  final int passengerCount;

  const TripSearchFilter({
    this.departureCountry,
    this.departureProvince,
    this.departureCity,
    this.arrivalCountry,
    this.arrivalProvince,
    this.arrivalCity,
    this.travelDate,
    this.passengerCount = 1,
  });

  bool get isEmpty {
    return departureCountry == null &&
        departureProvince == null &&
        departureCity == null &&
        arrivalCountry == null &&
        arrivalProvince == null &&
        arrivalCity == null &&
        travelDate == null &&
        passengerCount == 1;
  }
}

enum SearchMatchType { exact, countryFallback, empty }

class SearchResult {
  final List<Trip> trips;
  final SearchMatchType matchType;
  const SearchResult({required this.trips, required this.matchType});
}

class TripSearchService {
  SearchResult applyFilters(List<Trip> allTrips, TripSearchFilter filter) {
    final now = DateTime.now();

    // Base availability check
    bool isAvailable(Trip trip) {
      if (trip.status != 'published') {
        return false;
      }
      if (trip.departureTime.isBefore(now)) {
        return false;
      }
      if (trip.remainingSeats < filter.passengerCount) {
        return false;
      }

      // Optional calendar date matching
      if (filter.travelDate != null) {
        final filterDate = filter.travelDate!;
        final tripDate = trip.departureTime;
        if (tripDate.year != filterDate.year ||
            tripDate.month != filterDate.month ||
            tripDate.day != filterDate.day) {
          return false;
        }
      }

      return true;
    }

    if (filter.isEmpty) {
      final results = allTrips.where(isAvailable).toList();
      results.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return SearchResult(trips: results, matchType: SearchMatchType.exact);
    }

    // Normalization helper for Arabic text and spaces
    String normalize(String input) {
      if (input.isEmpty) return '';
      var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
      s = s.replaceAll(RegExp(r'[أإآ]'), 'ا');
      s = s.replaceAll('ى', 'ي');
      s = s.replaceAll('ة', 'ه');
      s = s.replaceAll('ـ', '');
      return s.toLowerCase();
    }

    bool matchCountry(String tripId, String tripName, Country? filterCountry) {
      if (filterCountry == null) return true;
      if (tripId.trim().isNotEmpty &&
          tripId.trim().toLowerCase() ==
              filterCountry.id.trim().toLowerCase()) {
        return true;
      }
      return normalize(tripName) == normalize(filterCountry.nameAr);
    }

    bool matchProvince(
      String tripId,
      String tripName,
      Governorate? filterProv,
    ) {
      if (filterProv == null) return true;
      if (tripId.trim().isNotEmpty &&
          tripId.trim().toLowerCase() == filterProv.id.trim().toLowerCase()) {
        return true;
      }
      return normalize(tripName) == normalize(filterProv.nameAr);
    }

    bool matchCity(String tripId, String tripName, City? filterCity) {
      if (filterCity == null) return true;
      if (tripId.trim().isNotEmpty &&
          tripId.trim().toLowerCase() == filterCity.id.trim().toLowerCase()) {
        return true;
      }
      return normalize(tripName) == normalize(filterCity.nameAr);
    }

    // 1. EXACT SEARCH PASS
    final exactResults = allTrips.where((trip) {
      if (!isAvailable(trip)) return false;

      if (!matchCountry(
        trip.departureCountryId,
        trip.departureCountry,
        filter.departureCountry,
      )) {
        return false;
      }
      if (!matchProvince(
        trip.departureProvinceId,
        trip.departureProvince,
        filter.departureProvince,
      )) {
        return false;
      }
      if (!matchCity(
        trip.departureCityId,
        trip.departureCity,
        filter.departureCity,
      )) {
        return false;
      }

      if (!matchCountry(
        trip.arrivalCountryId,
        trip.arrivalCountry,
        filter.arrivalCountry,
      )) {
        return false;
      }
      if (!matchProvince(
        trip.arrivalProvinceId,
        trip.arrivalProvince,
        filter.arrivalProvince,
      )) {
        return false;
      }
      if (!matchCity(
        trip.arrivalCityId,
        trip.arrivalCity,
        filter.arrivalCity,
      )) {
        return false;
      }

      return true;
    }).toList();

    if (exactResults.isNotEmpty) {
      exactResults.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return SearchResult(
        trips: exactResults,
        matchType: SearchMatchType.exact,
      );
    }

    // 2. FALLBACK SEARCH PASS (Ignore Provinces/Cities, match Countries only)
    final fallbackResults = allTrips.where((trip) {
      if (!isAvailable(trip)) return false;

      if (filter.departureCountry != null &&
          trip.departureCountryId.trim().toLowerCase() !=
              filter.departureCountry!.id.trim().toLowerCase()) {
        return false;
      }

      if (filter.arrivalCountry != null &&
          trip.arrivalCountryId.trim().toLowerCase() !=
              filter.arrivalCountry!.id.trim().toLowerCase()) {
        return false;
      }

      return true;
    }).toList();

    if (fallbackResults.isNotEmpty) {
      fallbackResults.sort(
        (a, b) => a.departureTime.compareTo(b.departureTime),
      );
      return SearchResult(
        trips: fallbackResults,
        matchType: SearchMatchType.countryFallback,
      );
    }

    // 3. NO RESULTS
    return const SearchResult(trips: [], matchType: SearchMatchType.empty);
  }

  List<Trip> getSuggestions(List<Trip> allTrips) {
    final now = DateTime.now();

    final suggestions = allTrips.where((trip) {
      if (trip.status != 'published') {
        return false;
      }
      if (trip.remainingSeats <= 0) {
        return false;
      }
      if (trip.departureTime.isBefore(now)) {
        return false;
      }
      return true;
    }).toList();

    suggestions.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return suggestions.take(10).toList();
  }
}
