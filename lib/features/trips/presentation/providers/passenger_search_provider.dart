import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/geo/domain/models/country.dart';
import 'package:rahal/features/geo/domain/models/governorate.dart';
import 'package:rahal/features/geo/domain/models/city.dart';
import 'package:rahal/core/providers/shared_trip_provider.dart';
import 'package:rahal/features/trips/domain/services/trip_search_service.dart';
import 'package:rahal/core/utils/app_logger.dart';

class PassengerSearchState {
  final Country? departureCountry;
  final Governorate? departureProvince;
  final City? departureCity;
  final Country? arrivalCountry;
  final Governorate? arrivalProvince;
  final City? arrivalCity;
  final DateTime? travelDate;
  final int passengerCount;

  PassengerSearchState({
    this.departureCountry,
    this.departureProvince,
    this.departureCity,
    this.arrivalCountry,
    this.arrivalProvince,
    this.arrivalCity,
    this.travelDate,
    this.passengerCount = 1,
  });

  PassengerSearchState copyWith({
    Country? departureCountry,
    Governorate? departureProvince,
    City? departureCity,
    Country? arrivalCountry,
    Governorate? arrivalProvince,
    City? arrivalCity,
    DateTime? travelDate,
    int? passengerCount,
    bool clearDepartureProvince = false,
    bool clearDepartureCity = false,
    bool clearArrivalProvince = false,
    bool clearArrivalCity = false,
    bool clearTravelDate = false,
  }) {
    return PassengerSearchState(
      departureCountry: departureCountry ?? this.departureCountry,
      departureProvince: clearDepartureProvince
          ? null
          : (departureProvince ?? this.departureProvince),
      departureCity: (clearDepartureProvince || clearDepartureCity)
          ? null
          : (departureCity ?? this.departureCity),
      arrivalCountry: arrivalCountry ?? this.arrivalCountry,
      arrivalProvince: clearArrivalProvince
          ? null
          : (arrivalProvince ?? this.arrivalProvince),
      arrivalCity: (clearArrivalProvince || clearArrivalCity)
          ? null
          : (arrivalCity ?? this.arrivalCity),
      travelDate: clearTravelDate ? null : (travelDate ?? this.travelDate),
      passengerCount: passengerCount ?? this.passengerCount,
    );
  }
}

class PassengerSearchNotifier extends StateNotifier<PassengerSearchState> {
  PassengerSearchNotifier() : super(PassengerSearchState());

  void setDepartureCountry(Country country) {
    state = state.copyWith(
      departureCountry: country,
      clearDepartureProvince: true,
      clearDepartureCity: true,
    );
  }

  void setDepartureProvince(Governorate province) {
    state = state.copyWith(
      departureProvince: province,
      clearDepartureCity: true,
    );
  }

  void setDepartureCity(City city) {
    state = state.copyWith(departureCity: city);
  }

  void setArrivalCountry(Country country) {
    state = state.copyWith(
      arrivalCountry: country,
      clearArrivalProvince: true,
      clearArrivalCity: true,
    );
  }

  void setArrivalProvince(Governorate province) {
    state = state.copyWith(arrivalProvince: province, clearArrivalCity: true);
  }

  void setArrivalCity(City city) {
    state = state.copyWith(arrivalCity: city);
  }

  void setTravelDate(DateTime date) {
    state = state.copyWith(travelDate: date);
  }

  void clearTravelDate() {
    state = state.copyWith(clearTravelDate: true);
  }

  void setPassengerCount(int count) =>
      state = state.copyWith(passengerCount: count);

  void swapLocations() {
    final tempCountry = state.departureCountry;
    final tempProvince = state.departureProvince;
    final tempCity = state.departureCity;

    state = state.copyWith(
      departureCountry: state.arrivalCountry,
      departureProvince: state.arrivalProvince,
      departureCity: state.arrivalCity,
      arrivalCountry: tempCountry,
      arrivalProvince: tempProvince,
      arrivalCity: tempCity,
    );
  }

  void resetSearch() {
    state = PassengerSearchState();
  }
}

final passengerSearchFilterProvider =
    StateNotifierProvider<PassengerSearchNotifier, PassengerSearchState>((ref) {
      return PassengerSearchNotifier();
    });

final searchResultsProvider = Provider<AsyncValue<SearchResult>>((ref) {
  final allTrips = ref.watch(sharedTripsProvider);
  final filterState = ref.watch(passengerSearchFilterProvider);
  final searchService = TripSearchService();

  return allTrips.whenData((trips) {
    final filter = TripSearchFilter(
      departureCountry: filterState.departureCountry,
      departureProvince: filterState.departureProvince,
      departureCity: filterState.departureCity,
      arrivalCountry: filterState.arrivalCountry,
      arrivalProvince: filterState.arrivalProvince,
      arrivalCity: filterState.arrivalCity,
      travelDate: filterState.travelDate,
      passengerCount: filterState.passengerCount,
    );

    AppLogger.logSearch(filter, trips.length);
    final result = searchService.applyFilters(trips, filter);
    AppLogger.logSearchResults(result.trips.length);

    return result;
  });
});
