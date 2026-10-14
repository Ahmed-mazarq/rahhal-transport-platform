import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/support/data/repositories/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/data/repositories/support_chat_repository_impl.dart';
import '../../features/support/domain/repositories/support_chat_repository.dart';
import '../../features/trips/data/repositories/booking_chat_repository_impl.dart';
import '../../features/trips/domain/repositories/booking_chat_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/fleet/data/repositories/fleet_repository_impl.dart';
import '../../features/fleet/domain/repositories/fleet_repository.dart';
import '../../features/geo/data/repositories/geo_repository_impl.dart';
import '../../core/services/storage/payment_proof_storage.dart';
import '../../features/geo/domain/repositories/geo_repository.dart';

import '../../features/trips/data/repositories/trip_repository_impl.dart';
import '../../features/trips/domain/repositories/trip_repository.dart';
import '../../features/parcel/data/repositories/parcel_repository_impl.dart';
import '../../features/parcel/domain/repositories/parcel_repository.dart';
import '../../features/parcel/data/repositories/parcel_chat_repository_impl.dart';
import '../../features/parcel/domain/repositories/parcel_chat_repository.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/verification/data/repositories/verification_repository_impl.dart';
import '../../features/verification/domain/repositories/verification_repository.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/passenger/data/repositories/passenger_repository_impl.dart';
import '../../features/passenger/domain/repositories/passenger_repository.dart';
import '../../features/driver/data/repositories/driver_repository_impl.dart';
import '../../features/driver/domain/repositories/driver_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(ref.watch(firestoreProvider), ref);
});

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepositoryImpl(ref.watch(firestoreProvider), ref);
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(firestoreProvider));
});

final geoRepositoryProvider = Provider<GeoRepository>((ref) {
  return GeoRepositoryImpl(ref.watch(firestoreProvider));
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepositoryImpl(ref.watch(firestoreProvider));
});

final parcelRepositoryProvider = Provider<ParcelRepository>((ref) {
  return ParcelRepositoryImpl(ref.watch(firestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(firestoreProvider));
});

final passengerRepositoryProvider = Provider<PassengerRepository>((ref) {
  return PassengerRepositoryImpl(ref.watch(firestoreProvider));
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepositoryImpl(ref.watch(firestoreProvider));
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final authState = ref.watch(authProvider);
  String role = 'passenger';
  if (authState is Authenticated) {
    role = authState.user.role;
  }
  if (role == 'admin') {
    role =
        'passenger'; // Admins use AdminSupportRepository for list, but might use SupportRepository for general actions, default to passenger if generic actions needed.
  }
  return SupportRepositoryImpl(
    ref.watch(firestoreProvider),
    collectionPrefix: role,
  );
});

final supportChatRepositoryProvider = Provider<SupportChatRepository>((ref) {
  final authState = ref.watch(authProvider);
  String role = 'passenger';
  if (authState is Authenticated) {
    role = authState.user.role;
  }
  if (role == 'admin') role = 'passenger';
  return SupportChatRepositoryImpl(
    ref.watch(firestoreProvider),
    collectionPrefix: role,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final authState = ref.watch(authProvider);
  String role = 'passenger';
  if (authState is Authenticated) {
    role = authState.user.role;
  }
  if (role == 'admin') role = 'passenger';

  return SettingsRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(sharedPreferencesProvider),
    collectionPrefix: role,
  );
});

// --- Storage Providers ---
final paymentProofStorageProvider = Provider<PaymentProofStorage>((ref) {
  // Uses production Supabase Storage implementation
  return SupabasePaymentProofStorage();
});

final bookingChatRepositoryProvider = Provider<BookingChatRepository>((ref) {
  return BookingChatRepositoryImpl();
});

final parcelChatRepositoryProvider = Provider<ParcelChatRepository>((ref) {
  return ParcelChatRepositoryImpl();
});
