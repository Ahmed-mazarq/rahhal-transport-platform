import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/user_repository.dart';
import '../repositories/firestore_user_repository.dart';
import '../services/user_service.dart';
import '../services/firebase_user_service.dart';
import '../repositories/driver_repository.dart';
import '../repositories/firestore_driver_repository.dart';
import '../services/driver_service.dart';
import '../services/firebase_driver_service.dart';
import '../repositories/company_repository.dart';
import '../repositories/firestore_company_repository.dart';
import '../services/company_service.dart';
import '../services/firebase_company_service.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/firestore_vehicle_repository.dart';
import '../services/vehicle_service.dart';
import '../services/firebase_vehicle_service.dart';
import '../repositories/trip_repository.dart';
import '../repositories/firestore_trip_repository.dart';
import '../services/destination_service.dart';
import '../services/firebase_destination_service.dart';
import '../repositories/destination_repository.dart';
import '../repositories/firestore_destination_repository.dart';
import '../services/trip_service.dart';
import '../services/firebase_trip_service.dart';
import '../repositories/trip_request_repository.dart';
import '../repositories/firestore_trip_request_repository.dart';
import '../services/trip_request_service.dart';
import '../services/firebase_trip_request_service.dart';
import '../repositories/booking_repository.dart';
import '../repositories/firestore_booking_repository.dart';
import '../services/booking_service.dart';
import '../services/firebase_booking_service.dart';
import '../repositories/booking_history_repository.dart';
import '../repositories/firestore_booking_history_repository.dart';
import '../services/booking_history_service.dart';
import '../services/firebase_booking_history_service.dart';
import '../repositories/notification_repository.dart';
import '../repositories/firestore_notification_repository.dart';
import '../services/notification_service.dart';
import '../services/firebase_notification_service.dart';
import '../repositories/news_repository.dart';
import '../repositories/firestore_news_repository.dart';
import '../services/news_service.dart';
import '../services/firebase_news_service.dart';

import '../repositories/governorate_repository.dart';
import '../repositories/firestore_governorate_repository.dart';
import '../services/governorate_service.dart';
import '../services/firebase_governorate_service.dart';
import '../repositories/city_repository.dart';
import '../repositories/firestore_city_repository.dart';
import '../services/city_service.dart';
import '../services/firebase_city_service.dart';
import '../repositories/service_repository.dart';
import '../repositories/firestore_service_repository.dart';
import '../services/service_service.dart';
import '../services/firebase_service_service.dart';
import '../repositories/advertisement_repository.dart';
import '../repositories/firestore_advertisement_repository.dart';
import '../services/advertisement_service.dart';
import '../services/firebase_advertisement_service.dart';
import '../repositories/banner_repository.dart';
import '../repositories/firestore_banner_repository.dart';
import '../services/banner_service.dart';
import '../services/firebase_banner_service.dart';
import '../repositories/settings_repository.dart';
import '../repositories/firestore_settings_repository.dart';
import '../services/settings_service.dart';
import '../services/firebase_settings_service.dart';
import '../repositories/rating_repository.dart';
import '../repositories/firestore_rating_repository.dart';
import '../services/rating_service.dart';
import '../services/firebase_rating_service.dart';
import '../repositories/report_repository.dart';
import '../repositories/firestore_report_repository.dart';
import '../services/report_service.dart';
import '../services/firebase_report_service.dart';
import '../cache/memory_cache.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// Services
final userServiceProvider = Provider<UserService>((ref) {
  return FirebaseUserService(firestore: ref.watch(firestoreProvider));
});
final driverServiceProvider = Provider<DriverService>((ref) {
  return FirebaseDriverService(firestore: ref.watch(firestoreProvider));
});
final companyServiceProvider = Provider<CompanyService>((ref) {
  return FirebaseCompanyService(firestore: ref.watch(firestoreProvider));
});
final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return FirebaseVehicleService(firestore: ref.watch(firestoreProvider));
});
final tripServiceProvider = Provider<TripService>((ref) {
  return FirebaseTripService(firestore: ref.watch(firestoreProvider));
});
final tripRequestServiceProvider = Provider<TripRequestService>((ref) {
  return FirebaseTripRequestService(firestore: ref.watch(firestoreProvider));
});
final bookingServiceProvider = Provider<BookingService>((ref) {
  return FirebaseBookingService(firestore: ref.watch(firestoreProvider));
});
final bookingHistoryServiceProvider = Provider<BookingHistoryService>((ref) {
  return FirebaseBookingHistoryService(firestore: ref.watch(firestoreProvider));
});
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return FirebaseNotificationService(firestore: ref.watch(firestoreProvider));
});
final newsServiceProvider = Provider<NewsService>((ref) {
  return FirebaseNewsService(firestore: ref.watch(firestoreProvider));
});

final governorateServiceProvider = Provider<GovernorateService>((ref) {
  return FirebaseGovernorateService(firestore: ref.watch(firestoreProvider));
});
final cityServiceProvider = Provider<CityService>((ref) {
  return FirebaseCityService(firestore: ref.watch(firestoreProvider));
});
final serviceServiceProvider = Provider<ServiceService>((ref) {
  return FirebaseServiceService(firestore: ref.watch(firestoreProvider));
});
final advertisementServiceProvider = Provider<AdvertisementService>((ref) {
  return FirebaseAdvertisementService(firestore: ref.watch(firestoreProvider));
});
final bannerServiceProvider = Provider<BannerService>((ref) {
  return FirebaseBannerService(firestore: ref.watch(firestoreProvider));
});
final destinationServiceProvider = Provider<DestinationService>((ref) {
  return FirebaseDestinationService(FirebaseFirestore.instance);
});
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return FirebaseSettingsService(firestore: ref.watch(firestoreProvider));
});
final ratingServiceProvider = Provider<RatingService>((ref) {
  return FirebaseRatingService(firestore: ref.watch(firestoreProvider));
});
final reportServiceProvider = Provider<ReportService>((ref) {
  return FirebaseReportService(firestore: ref.watch(firestoreProvider));
});

// Repositories
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(
    ref.watch(userServiceProvider),
    cache: MemoryCache(),
  );
});
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return FirestoreDriverRepository(
    ref.watch(driverServiceProvider),
    cache: MemoryCache(),
  );
});
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return FirestoreCompanyRepository(
    ref.watch(companyServiceProvider),
    cache: MemoryCache(),
  );
});
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return FirestoreVehicleRepository(
    ref.watch(vehicleServiceProvider),
    ref,
    cache: MemoryCache(),
  );
});
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return FirestoreTripRepository(
    ref.watch(tripServiceProvider),
    ref,
    cache: MemoryCache(),
  );
});
final tripRequestRepositoryProvider = Provider<TripRequestRepository>((ref) {
  return FirestoreTripRequestRepository(
    ref.watch(tripRequestServiceProvider),
    cache: MemoryCache(),
  );
});
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return FirestoreBookingRepository(
    ref.watch(bookingServiceProvider),
    ref,
    cache: MemoryCache(),
  );
});
final bookingHistoryRepositoryProvider = Provider<BookingHistoryRepository>((
  ref,
) {
  return FirestoreBookingHistoryRepository(
    ref.watch(bookingHistoryServiceProvider),
    cache: MemoryCache(),
  );
});
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(
    ref.watch(notificationServiceProvider),
    cache: MemoryCache(),
  );
});
final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return FirestoreNewsRepository(
    ref.watch(newsServiceProvider),
    cache: MemoryCache(),
  );
});

final governorateRepositoryProvider = Provider<GovernorateRepository>((ref) {
  return FirestoreGovernorateRepository(
    ref.watch(governorateServiceProvider),
    cache: MemoryCache(),
  );
});
final cityRepositoryProvider = Provider<CityRepository>((ref) {
  return FirestoreCityRepository(
    ref.watch(cityServiceProvider),
    cache: MemoryCache(),
  );
});
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return FirestoreServiceRepository(
    ref.watch(serviceServiceProvider),
    cache: MemoryCache(),
  );
});
final advertisementRepositoryProvider = Provider<AdvertisementRepository>((
  ref,
) {
  return FirestoreAdvertisementRepository(
    ref.watch(advertisementServiceProvider),
    cache: MemoryCache(),
  );
});
final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return FirestoreBannerRepository(
    ref.watch(bannerServiceProvider),
    cache: MemoryCache(),
  );
});
final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return FirestoreDestinationRepository(
    ref.watch(destinationServiceProvider),
    cache: MemoryCache(),
  );
});
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FirestoreSettingsRepository(
    ref.watch(settingsServiceProvider),
    cache: MemoryCache(),
  );
});
final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return FirestoreRatingRepository(
    ref.watch(ratingServiceProvider),
    cache: MemoryCache(),
  );
});
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return FirestoreReportRepository(
    ref.watch(reportServiceProvider),
    cache: MemoryCache(),
  );
});
