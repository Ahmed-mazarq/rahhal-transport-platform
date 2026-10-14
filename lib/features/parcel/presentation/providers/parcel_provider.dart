import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/parcel_delivery.dart';
import '../../domain/models/parcel_event.dart';
import '../../../../core/services/notification_service.dart';

final passengerParcelsProvider =
    FutureProvider.family<List<ParcelDelivery>, String>((
      ref,
      passengerId,
    ) async {
      final repo = ref.watch(parcelRepositoryProvider);
      return repo.getPassengerParcels(passengerId);
    });

final driverParcelsProvider =
    FutureProvider.family<List<ParcelDelivery>, String>((ref, driverId) async {
      final repo = ref.watch(parcelRepositoryProvider);
      return repo.getDriverParcels(driverId);
    });

final marketplaceParcelsProvider = FutureProvider<List<ParcelDelivery>>((
  ref,
) async {
  final repo = ref.watch(parcelRepositoryProvider);
  return repo.getMarketplaceParcels();
});

class MatchedParcel {
  final ParcelDelivery parcel;
  final int score;
  final String matchReason;

  MatchedParcel({
    required this.parcel,
    required this.score,
    required this.matchReason,
  });
}

final matchedMarketplaceParcelsProvider =
    FutureProvider.family<List<MatchedParcel>, String>((ref, driverId) async {
      final allParcels = await ref.watch(marketplaceParcelsProvider.future);
      if (allParcels.isEmpty) return [];

      final tripRepo = ref.watch(tripRepositoryProvider);
      final driverTrips = await tripRepo.getDriverTrips(driverId);
      final activeTrips = driverTrips
          .where((t) => t.status == 'published' || t.status == 'ongoing')
          .toList();

      if (activeTrips.isEmpty) {
        // No active trips, just return them with low priority
        return allParcels
            .map(
              (p) =>
                  MatchedParcel(parcel: p, score: 0, matchReason: 'رحلة بديلة'),
            )
            .toList();
      }

      final matchedList = <MatchedParcel>[];

      for (final parcel in allParcels) {
        int bestScore = 0;
        String bestReason = 'رحلة بديلة';

        for (final trip in activeTrips) {
          int score = 0;
          String reason = '';

          final parcelOriginCountry = parcel.originCountryId
              .trim()
              .toLowerCase();
          final parcelDestCountry = parcel.destinationCountryId
              .trim()
              .toLowerCase();
          final tripOriginCountry = trip.departureCountryId
              .trim()
              .toLowerCase();
          final tripDestCountry = trip.arrivalCountryId.trim().toLowerCase();

          if (parcelOriginCountry == tripOriginCountry &&
              parcelDestCountry == tripDestCountry) {
            score = 50;
            reason = 'نفس الوجهة';

            final parcelOriginProv = parcel.originProvinceId
                .trim()
                .toLowerCase();
            final parcelDestProv = parcel.destinationProvinceId
                .trim()
                .toLowerCase();
            final tripOriginProv = trip.departureProvinceId
                .trim()
                .toLowerCase();
            final tripDestProv = trip.arrivalProvinceId.trim().toLowerCase();

            if (parcelOriginProv.isNotEmpty &&
                tripOriginProv.isNotEmpty &&
                parcelOriginProv == tripOriginProv &&
                parcelDestProv.isNotEmpty &&
                tripDestProv.isNotEmpty &&
                parcelDestProv == tripDestProv) {
              score = 100;
              reason = 'مطابق للمحافظة';

              final parcelOriginCity = parcel.originCityId.trim().toLowerCase();
              final parcelDestCity = parcel.destinationCityId
                  .trim()
                  .toLowerCase();
              final tripOriginCity = trip.departureCityId.trim().toLowerCase();
              final tripDestCity = trip.arrivalCityId.trim().toLowerCase();

              if (parcelOriginCity.isNotEmpty &&
                  tripOriginCity.isNotEmpty &&
                  parcelOriginCity == tripOriginCity &&
                  parcelDestCity.isNotEmpty &&
                  tripDestCity.isNotEmpty &&
                  parcelDestCity == tripDestCity) {
                score = 110;
                reason = 'مطابق لمسارك';
              }
            }

            // Stop check
            if (score < 110 && trip.stops.isNotEmpty) {
              bool originMatched = false;
              bool destMatched = false;

              if (tripOriginProv == parcelOriginProv) originMatched = true;
              if (tripDestProv == parcelDestProv) destMatched = true;

              for (final stop in trip.stops) {
                final stopProv = stop.provinceId.trim().toLowerCase();
                if (!originMatched && stopProv == parcelOriginProv) {
                  originMatched = true;
                }
                if (originMatched && stopProv == parcelDestProv) {
                  destMatched = true;
                }
              }

              if (originMatched && destMatched) {
                score = 80;
                reason = 'يمر عبر مسارك';
              }
            }
          }

          if (score > bestScore) {
            bestScore = score;
            bestReason = reason;
          }
        }

        matchedList.add(
          MatchedParcel(
            parcel: parcel,
            score: bestScore,
            matchReason: bestReason,
          ),
        );
      }

      // Sort by score descending, then by creation date
      matchedList.sort((a, b) {
        if (a.score != b.score) return b.score.compareTo(a.score);
        return b.parcel.createdAt.compareTo(a.parcel.createdAt);
      });

      return matchedList;
    });

final parcelDetailsProvider = StreamProvider.family<ParcelDelivery?, String>((
  ref,
  parcelId,
) {
  final repo = ref.watch(parcelRepositoryProvider);
  return repo.watchParcelDelivery(parcelId);
});

final parcelEventsProvider = StreamProvider.family<List<ParcelEvent>, String>((
  ref,
  parcelId,
) {
  final repo = ref.watch(parcelRepositoryProvider);
  return repo.watchParcelEvents(parcelId);
});

class ParcelActionNotifier extends StateNotifier<AsyncValue<void>> {
  ParcelActionNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<String?> createParcel(ParcelDelivery parcel) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(parcelRepositoryProvider);
      final id = await repo.createParcelRequest(parcel);

      await repo.addParcelEvent(
        ParcelEvent(
          id: '',
          parcelId: id,
          type: 'status_change',
          status: parcel.status,
          actorId: parcel.senderId,
          actorRole: 'passenger',
          description: 'تم إنشاء طلب الطرد',
          timestamp: DateTime.now(),
        ),
      );

      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateStatus(
    String parcelId,
    String newStatus,
    String actorId,
    String actorRole,
    String description,
  ) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(parcelRepositoryProvider);

      // Get the parcel to update rejection fields
      final parcelDoc = await FirebaseFirestore.instance
          .collection('parcel_requests')
          .doc(parcelId)
          .get();
      if (parcelDoc.exists) {
        await parcelDoc.reference.update({'status': newStatus});
      }

      await repo.addParcelEvent(
        ParcelEvent(
          id: '',
          parcelId: parcelId,
          type: 'status_change',
          status: newStatus,
          actorId: actorId,
          actorRole: actorRole,
          description: description,
          timestamp: DateTime.now(),
        ),
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> rejectParcel(
    String parcelId,
    String actorId,
    String reason,
  ) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(parcelRepositoryProvider);

      await FirebaseFirestore.instance
          .collection('parcel_requests')
          .doc(parcelId)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'rejectedBy': actorId,
            'rejectedAt': DateTime.now().toIso8601String(),
          });

      await repo.addParcelEvent(
        ParcelEvent(
          id: '',
          parcelId: parcelId,
          type: 'status_change',
          status: 'rejected',
          actorId: actorId,
          actorRole: 'driver',
          description: 'تم رفض الطرد: $reason',
          timestamp: DateTime.now(),
        ),
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> acceptParcel(
    String parcelId,
    String driverId,
    String driverName,
  ) async {
    state = const AsyncValue.loading();
    try {
      final docRef = FirebaseFirestore.instance
          .collection('parcel_requests')
          .doc(parcelId);
      final repo = ref.read(parcelRepositoryProvider);

      final driverRepo = ref.read(driverRepositoryProvider);
      final fleetRepo = ref.read(fleetRepositoryProvider);

      final profile = await driverRepo.getDriverProfile(driverId);
      final vehicles = await fleetRepo.getDriverVehicles(driverId);
      final primaryVehicle = vehicles.isNotEmpty
          ? vehicles.firstWhere(
              (v) => v.id == profile?.primaryVehicleId,
              orElse: () => vehicles.first,
            )
          : null;

      final result = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return null;

        final data = snapshot.data()!;
        final status = data['status'] as String?;
        final currentDriverId = data['driverId'] as String?;
        final senderId = data['senderId'] as String?;

        if (senderId == driverId) {
          return null; // Driver cannot accept their own parcel
        }

        // Only allow acceptance if searching or specifically pending for this driver
        if (status == 'searching_for_carrier' ||
            (status == 'pending_carrier_acceptance' &&
                currentDriverId == driverId)) {
          final Map<String, dynamic> updateData = {
            'status': 'accepted',
            'driverId': driverId,
            'updatedAt': DateTime.now().toIso8601String(),
            'carrierName': driverName,
            if (profile != null) 'carrierRating': profile.rating,
            if (profile != null) 'carrierTripsCount': profile.completedTrips,
            if (primaryVehicle != null) 'vehicleType': primaryVehicle.type,
            if (primaryVehicle != null) 'vehicleModel': primaryVehicle.model,
            if (primaryVehicle != null) 'vehicleColor': primaryVehicle.color,
            if (primaryVehicle != null) 'vehicleId': primaryVehicle.id,
          };
          transaction.update(docRef, updateData);
          return senderId;
        }
        return null;
      });

      if (result != null) {
        await SystemNotificationService.sendNotification(
          title: 'تم قبول طردك',
          body: 'تم قبول طردك من قبل السائق $driverName',
          targetUserId: result,
          category: 'parcel',
          payload: {
            'parcelId': parcelId,
            'driverId': driverId,
            'type': 'parcel_accepted',
          },
        );

        await repo.addParcelEvent(
          ParcelEvent(
            id: '',
            parcelId: parcelId,
            type: 'status_change',
            status: 'accepted',
            actorId: driverId,
            actorRole: 'driver',
            description: 'تم قبول الطرد من قبل السائق $driverName',
            timestamp: DateTime.now(),
          ),
        );
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error(
          'عذراً، تم قبول الطرد مسبقاً أو أنه غير متاح',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final parcelActionProvider =
    StateNotifierProvider<ParcelActionNotifier, AsyncValue<void>>((ref) {
      return ParcelActionNotifier(ref);
    });
