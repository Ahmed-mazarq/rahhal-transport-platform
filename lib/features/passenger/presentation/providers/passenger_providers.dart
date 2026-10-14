import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/passenger_profile.dart';
import '../../../trips/domain/models/booking.dart';

final passengerProfileProvider = FutureProvider<PassengerProfile?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is Authenticated) {
    final repo = ref.watch(passengerRepositoryProvider);
    return await repo.getPassengerProfile(authState.user.uid);
  }
  return null;
});

final passengerBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is Authenticated) {
    final repo = ref.watch(tripRepositoryProvider);
    return await repo.getPassengerBookings(authState.user.uid);
  }
  return [];
});
