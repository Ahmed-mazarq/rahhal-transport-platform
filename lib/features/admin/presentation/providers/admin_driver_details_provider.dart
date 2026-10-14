import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/common/models/driver_model.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';

class DriverDetailsState {
  final bool isLoading;
  final String? error;
  final DriverModel? driver;
  final List<Trip> trips;
  final List<Booking> bookings;
  final List<Map<String, dynamic>> driverDocuments;
  final List<Map<String, dynamic>> vehicleDocuments;

  DriverDetailsState({
    this.isLoading = true,
    this.error,
    this.driver,
    this.trips = const [],
    this.bookings = const [],
    this.driverDocuments = const [],
    this.vehicleDocuments = const [],
  });

  DriverDetailsState copyWith({
    bool? isLoading,
    String? error,
    DriverModel? driver,
    List<Trip>? trips,
    List<Booking>? bookings,
    List<Map<String, dynamic>>? driverDocuments,
    List<Map<String, dynamic>>? vehicleDocuments,
  }) {
    return DriverDetailsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      driver: driver ?? this.driver,
      trips: trips ?? this.trips,
      bookings: bookings ?? this.bookings,
      driverDocuments: driverDocuments ?? this.driverDocuments,
      vehicleDocuments: vehicleDocuments ?? this.vehicleDocuments,
    );
  }
}

class DriverDetailsNotifier extends StateNotifier<DriverDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DriverDetailsNotifier() : super(DriverDetailsState());

  Future<void> fetchData(String driverId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(driverId).get(),
        _firestore.collection('drivers').doc(driverId).get(),
        _firestore
            .collection('trips')
            .where('driverId', isEqualTo: driverId)
            .get(),
        _firestore
            .collection('bookings')
            .where('driverId', isEqualTo: driverId)
            .get(),
        _firestore
            .collection('driver_documents')
            .where('driverId', isEqualTo: driverId)
            .get(),
        _firestore
            .collection('vehicle_documents')
            .where('driverId', isEqualTo: driverId)
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final driverDoc = results[1] as DocumentSnapshot;
      final tripsSnap = results[2] as QuerySnapshot;
      final bookingsSnap = results[3] as QuerySnapshot;
      final driverDocsSnap = results[4] as QuerySnapshot;
      final vehicleDocsSnap = results[5] as QuerySnapshot;

      DriverModel? driver;
      Map<String, dynamic> mergedData = {};

      if (userDoc.exists) {
        mergedData.addAll(userDoc.data() as Map<String, dynamic>);
      }

      if (driverDoc.exists) {
        mergedData.addAll(driverDoc.data() as Map<String, dynamic>);
      }

      if (mergedData.isNotEmpty) {
        driver = DriverModel.fromFirestore(mergedData, driverId);
      }

      List<Trip> trips = tripsSnap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return Trip.fromJson(data);
      }).toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      List<Booking> bookings = bookingsSnap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return Booking.fromJson(data);
      }).toList();
      bookings.sort((a, b) {
        final dateA = a.createdAt ?? a.bookingTime;
        final dateB = b.createdAt ?? b.bookingTime;
        return dateB.compareTo(dateA);
      });

      List<Map<String, dynamic>> driverDocuments = driverDocsSnap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList();

      List<Map<String, dynamic>> vehicleDocuments = vehicleDocsSnap.docs.map((
        d,
      ) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList();

      // If vehicle documents are empty, try searching by vehicleId if driver has one
      if (vehicleDocuments.isEmpty &&
          driver != null &&
          driver.vehicleId.isNotEmpty) {
        final vDocs = await _firestore
            .collection('vehicle_documents')
            .where('vehicleId', isEqualTo: driver.vehicleId)
            .get();
        vehicleDocuments = vDocs.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      }

      // Merge driver.documents
      if (driver != null && driver.documents.isNotEmpty) {
        driver.documents.forEach((key, doc) {
          final isVehicleDoc =
              key.toLowerCase().contains('vehicle') ||
              key.toLowerCase().contains('car') ||
              key.toLowerCase().contains('registration') ||
              key.toLowerCase().contains('insurance');

          final docMap = {
            'id': key,
            'type': key,
            'status': doc.status,
            'url': doc.url,
            'notes': doc.notes,
          };

          if (isVehicleDoc) {
            if (!vehicleDocuments.any(
              (d) => d['type'] == key || d['id'] == key,
            )) {
              vehicleDocuments.add(docMap);
            }
          } else {
            if (!driverDocuments.any(
              (d) => d['type'] == key || d['id'] == key,
            )) {
              driverDocuments.add(docMap);
            }
          }
        });
      }

      state = state.copyWith(
        isLoading: false,
        driver: driver,
        trips: trips,
        bookings: bookings,
        driverDocuments: driverDocuments,
        vehicleDocuments: vehicleDocuments,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final driverDetailsProvider =
    StateNotifierProvider.family<
      DriverDetailsNotifier,
      DriverDetailsState,
      String
    >((ref, driverId) {
      return DriverDetailsNotifier()..fetchData(driverId);
    });
