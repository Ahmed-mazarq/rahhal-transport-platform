import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/common/models/company_model.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';

class CompanyDetailsState {
  final bool isLoading;
  final String? error;
  final CompanyModel? company;
  final List<Trip> trips;
  final List<Booking> bookings;

  CompanyDetailsState({
    this.isLoading = true,
    this.error,
    this.company,
    this.trips = const [],
    this.bookings = const [],
  });

  CompanyDetailsState copyWith({
    bool? isLoading,
    String? error,
    CompanyModel? company,
    List<Trip>? trips,
    List<Booking>? bookings,
  }) {
    return CompanyDetailsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      company: company ?? this.company,
      trips: trips ?? this.trips,
      bookings: bookings ?? this.bookings,
    );
  }
}

class CompanyDetailsNotifier extends StateNotifier<CompanyDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CompanyDetailsNotifier() : super(CompanyDetailsState());

  Future<void> fetchData(String companyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(companyId).get(),
        _firestore.collection('companies').doc(companyId).get(),
        _firestore
            .collection('trips')
            .where('companyId', isEqualTo: companyId)
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final companyDoc = results[1] as DocumentSnapshot;
      final tripsSnap = results[2] as QuerySnapshot;

      CompanyModel? company;
      Map<String, dynamic> mergedData = {};

      if (userDoc.exists) {
        mergedData.addAll(userDoc.data() as Map<String, dynamic>);
      }

      if (companyDoc.exists) {
        mergedData.addAll(companyDoc.data() as Map<String, dynamic>);
      }

      if (mergedData.isNotEmpty) {
        company = CompanyModel.fromFirestore(mergedData, companyId);
      }

      List<Trip> trips = tripsSnap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return Trip.fromJson(data);
      }).toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Get bookings for all these trips
      List<Booking> bookings = [];
      if (trips.isNotEmpty) {
        // Chunk trips because of whereIn limitation (max 10)
        final tripIds = trips.map((t) => t.id).toList();
        for (var i = 0; i < tripIds.length; i += 10) {
          final chunk = tripIds.sublist(
            i,
            i + 10 > tripIds.length ? tripIds.length : i + 10,
          );
          final bookingsSnap = await _firestore
              .collection('bookings')
              .where('tripId', whereIn: chunk)
              .get();
          bookings.addAll(
            bookingsSnap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return Booking.fromJson(data);
            }),
          );
        }
        bookings.sort((a, b) {
          final dateA = a.createdAt ?? a.bookingTime;
          final dateB = b.createdAt ?? b.bookingTime;
          return dateB.compareTo(dateA);
        });
      }

      state = state.copyWith(
        isLoading: false,
        company: company,
        trips: trips,
        bookings: bookings,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final companyDetailsProvider =
    StateNotifierProvider.family<
      CompanyDetailsNotifier,
      CompanyDetailsState,
      String
    >((ref, companyId) {
      return CompanyDetailsNotifier()..fetchData(companyId);
    });
