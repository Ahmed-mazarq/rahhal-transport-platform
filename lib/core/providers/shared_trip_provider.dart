import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/core/providers/repository_providers.dart';

final sharedTripsProvider = StreamProvider<List<Trip>>((ref) {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return tripRepository.watchTrips();
});
