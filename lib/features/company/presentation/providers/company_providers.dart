import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/company.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/branch.dart';
import '../../domain/repositories/company_repository.dart';
import '../../data/repositories/company_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/models/trip.dart';
import '../../../trips/domain/models/booking.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../../../driver/domain/models/driver_payment_method.dart';
import '../../../../core/providers/repository_providers.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepositoryImpl(FirebaseFirestore.instance);
});

final companyProfileProvider = FutureProvider.autoDispose<Company?>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return null;

  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getCompany(authState.user.uid);
});

final companyEmployeesProvider = FutureProvider.autoDispose<List<Employee>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return [];

  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getEmployees(authState.user.uid);
});

final companyBranchesProvider = FutureProvider.autoDispose<List<Branch>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return [];

  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getBranches(authState.user.uid);
});

final companyTripsProvider = FutureProvider.autoDispose<List<Trip>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getCompanyTrips(authState.user.uid);
});

final companyVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getCompanyVehicles(authState.user.uid);
});

final companyBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getCompanyBookings(authState.user.uid);
});

final companyPaymentMethodsProvider =
    StreamProvider.autoDispose<List<DriverPaymentMethod>>((ref) {
      final authState = ref.watch(authProvider);
      if (authState is! Authenticated) return const Stream.empty();

      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('company_payment_methods')
          .where('companyId', isEqualTo: authState.user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) =>
                      DriverPaymentMethod.fromJson(doc.data()..['id'] = doc.id),
                )
                .toList(),
          );
    });
