import '../models/passenger_profile.dart';

abstract class PassengerRepository {
  Future<PassengerProfile?> getPassengerProfile(String uid);
  Future<void> updatePassengerProfile(PassengerProfile profile);
  Future<void> addFavoriteDriver(String uid, String driverId);
  Future<void> removeFavoriteDriver(String uid, String driverId);
  Future<void> addFavoritePlace(String uid, Map<String, dynamic> place);
  Future<void> removeFavoritePlace(String uid, String placeId);
  Future<void> updateWalletBalance(String uid, double amount);
}
