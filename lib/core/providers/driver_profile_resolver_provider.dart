import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/driver/domain/models/driver_profile.dart';
import 'repository_providers.dart';

/// Resolves a driver profile efficiently by driverId.
/// Riverpod's `FutureProvider.family` caches the result automatically
/// preventing N+1 queries when multiple trips from the same driver are loaded.
final driverProfileResolverProvider =
    FutureProvider.family<DriverProfile?, String>((ref, driverId) async {
      if (driverId.isEmpty) return null;

      final repo = ref.watch(driverRepositoryProvider);
      return repo.getDriverProfile(driverId);
    });
