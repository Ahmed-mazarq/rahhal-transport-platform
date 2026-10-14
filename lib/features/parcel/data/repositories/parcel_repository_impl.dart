import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/parcel_delivery.dart';
import '../../domain/models/parcel_event.dart';
import '../../domain/models/parcel_trip_match.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../../../trips/domain/models/trip.dart';

class ParcelRepositoryImpl implements ParcelRepository {
  final FirebaseFirestore _firestore;

  ParcelRepositoryImpl(this._firestore);

  @override
  Future<String> createParcelRequest(ParcelDelivery parcel) async {
    final docRef = _firestore.collection('parcel_requests').doc();
    final newParcel = parcel.copyWith(id: docRef.id);
    await docRef.set(newParcel.toJson());
    return docRef.id;
  }

  @override
  Future<ParcelDelivery?> getParcelDelivery(String id) async {
    final doc = await _firestore.collection('parcel_requests').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ParcelDelivery.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Stream<ParcelDelivery?> watchParcelDelivery(String id) {
    return _firestore.collection('parcel_requests').doc(id).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return ParcelDelivery.fromJson(doc.data()!);
      }
      return null;
    });
  }

  @override
  Future<List<ParcelDelivery>> getPassengerParcels(String passengerId) async {
    final snapshot = await _firestore
        .collection('parcel_requests')
        .where('senderId', isEqualTo: passengerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ParcelDelivery.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<ParcelDelivery>> getDriverParcels(String driverId) async {
    final snapshot = await _firestore
        .collection('parcel_requests')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ParcelDelivery.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<ParcelDelivery>> getMarketplaceParcels() async {
    final snapshot = await _firestore
        .collection('parcel_requests')
        .where('status', isEqualTo: 'searching_for_carrier')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ParcelDelivery.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<ParcelDelivery>> getCompanyParcels(String companyId) async {
    final snapshot = await _firestore
        .collection('parcel_requests')
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ParcelDelivery.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> updateParcelStatus(String id, String status) async {
    await _firestore.collection('parcel_requests').doc(id).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateParcelPrice(String id, double price) async {
    await _firestore.collection('parcel_requests').doc(id).update({
      'price': price,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateParcelDriver(String id, String driverId) async {
    await _firestore.collection('parcel_requests').doc(id).update({
      'driverId': driverId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> addParcelEvent(ParcelEvent event) async {
    final docRef = _firestore
        .collection('parcel_requests')
        .doc(event.parcelId)
        .collection('events')
        .doc();
    final newEvent = ParcelEvent(
      id: docRef.id,
      parcelId: event.parcelId,
      type: event.type,
      status: event.status,
      actorId: event.actorId,
      actorRole: event.actorRole,
      description: event.description,
      location: event.location,
      metadata: event.metadata,
      timestamp: event.timestamp,
    );
    await docRef.set(newEvent.toJson());
  }

  @override
  Future<List<ParcelEvent>> getParcelEvents(String parcelId) async {
    final snapshot = await _firestore
        .collection('parcel_requests')
        .doc(parcelId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ParcelEvent.fromJson(doc.data()))
        .toList();
  }

  @override
  Stream<List<ParcelEvent>> watchParcelEvents(String parcelId) {
    return _firestore
        .collection('parcel_requests')
        .doc(parcelId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParcelEvent.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<ParcelTripMatch>> searchEligibleTripsForParcel({
    required String originCountryId,
    String? originProvinceId,
    String? originCityId,
    required String destinationCountryId,
    String? destinationProvinceId,
    String? destinationCityId,
    required double weight,
    required String size,
  }) async {
    final List<ParcelTripMatch> results = [];

    // Step 1: Query published trips matching countries
    final query = _firestore
        .collection('trips')
        .where(
          'departureCountryId',
          isEqualTo: originCountryId.trim().toLowerCase(),
        )
        .where(
          'arrivalCountryId',
          isEqualTo: destinationCountryId.trim().toLowerCase(),
        )
        .where('status', isEqualTo: 'published');

    final snapshot = await query.get();
    final trips = snapshot.docs
        .map((doc) => Trip.fromJson(doc.data()))
        .toList();

    for (var trip in trips) {
      // Basic capacity check
      // We assume default generous limits if they don't exist in legacy trips
      if (trip.parcelCapacityKg < weight) continue;

      // Check if departure time is in the future
      if (trip.departureTime.isBefore(DateTime.now())) continue;

      bool originMatched = false;
      bool destMatched = false;
      int score = 0;
      String matchType = '';
      String matchReason = '';
      String? pickupStopId;
      String? dropoffStopId;

      // 1. Exact City Match
      if (originCityId != null &&
          originCityId.isNotEmpty &&
          destinationCityId != null &&
          destinationCityId.isNotEmpty) {
        if (trip.departureCityId == originCityId.trim().toLowerCase() &&
            trip.arrivalCityId == destinationCityId.trim().toLowerCase()) {
          originMatched = true;
          destMatched = true;
          score = 110; // Better than province
          matchType = 'exact_city';
          matchReason = 'مطابق للمنطقة تماماً';
        }
      }

      // 2. Exact Province Match
      if (!originMatched || !destMatched) {
        if (originProvinceId != null &&
            originProvinceId.isNotEmpty &&
            destinationProvinceId != null &&
            destinationProvinceId.isNotEmpty) {
          if (trip.departureProvinceId ==
                  originProvinceId.trim().toLowerCase() &&
              trip.arrivalProvinceId ==
                  destinationProvinceId.trim().toLowerCase()) {
            originMatched = true;
            destMatched = true;
            score = 100;
            matchType = 'exact_province';
            matchReason = 'مطابق للمحافظة';
          }
        }
      }

      // 3. Stop Matching Fallback
      if (!originMatched || !destMatched) {
        int originIndex = -1;
        int destIndex = -1;

        // Check if origin is the trip departure
        if (trip.departureProvinceId ==
                originProvinceId?.trim().toLowerCase() ||
            trip.departureCityId == originCityId?.trim().toLowerCase()) {
          originIndex = 0; // Starts here
          originMatched = true;
        }

        // Check if dest is the trip arrival
        if (trip.arrivalProvinceId ==
                destinationProvinceId?.trim().toLowerCase() ||
            trip.arrivalCityId == destinationCityId?.trim().toLowerCase()) {
          destIndex = 9999; // Ends here
          destMatched = true;
        }

        // Search stops
        for (int i = 0; i < trip.stops.length; i++) {
          final stop = trip.stops[i];

          if (!originMatched && stop.pickupAllowed) {
            if ((originProvinceId != null &&
                    stop.provinceId == originProvinceId.trim().toLowerCase()) ||
                (originCityId != null &&
                    stop.cityId == originCityId.trim().toLowerCase())) {
              originIndex = stop.orderIndex;
              originMatched = true;
              pickupStopId = stop.id;
            }
          }

          if (!destMatched && stop.dropoffAllowed) {
            if ((destinationProvinceId != null &&
                    stop.provinceId ==
                        destinationProvinceId.trim().toLowerCase()) ||
                (destinationCityId != null &&
                    stop.cityId == destinationCityId.trim().toLowerCase())) {
              destIndex = stop.orderIndex;
              destMatched = true;
              dropoffStopId = stop.id;
            }
          }
        }

        // Direction matters: Origin must happen before Dest
        if (originMatched && destMatched && originIndex < destIndex) {
          if (score == 0) {
            score = 80;
            matchType = 'stop_fallback';
            matchReason = 'يمر عبر المسار المطلوب';
          }
        } else {
          // Reset if direction is wrong
          originMatched = false;
          destMatched = false;
        }
      }

      if (originMatched && destMatched) {
        results.add(
          ParcelTripMatch(
            trip: trip,
            score: score,
            matchType: matchType,
            matchReason: matchReason,
            pickupStopId: pickupStopId,
            dropoffStopId: dropoffStopId,
          ),
        );
      } else {
        // Country fallback match
        results.add(
          ParcelTripMatch(
            trip: trip,
            score: 50,
            matchType: 'country_fallback',
            matchReason: 'رحلة بديلة ضمن نفس الاتجاه',
            isFallback: true,
          ),
        );
      }
    }

    // Sort by highest score
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }
}
