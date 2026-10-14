import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/passenger_profile.dart';
import '../../domain/repositories/passenger_repository.dart';

class PassengerRepositoryImpl implements PassengerRepository {
  final FirebaseFirestore _firestore;

  PassengerRepositoryImpl(this._firestore);

  @override
  Future<PassengerProfile?> getPassengerProfile(String uid) async {
    final doc = await _firestore.collection('passengers').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return PassengerProfile.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> updatePassengerProfile(PassengerProfile profile) async {
    await _firestore
        .collection('passengers')
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> addFavoriteDriver(String uid, String driverId) async {
    await _firestore.collection('passengers').doc(uid).update({
      'favoriteDrivers': FieldValue.arrayUnion([driverId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> removeFavoriteDriver(String uid, String driverId) async {
    await _firestore.collection('passengers').doc(uid).update({
      'favoriteDrivers': FieldValue.arrayRemove([driverId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> addFavoritePlace(String uid, Map<String, dynamic> place) async {
    await _firestore.collection('passengers').doc(uid).update({
      'favoritePlaces': FieldValue.arrayUnion([place]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> removeFavoritePlace(String uid, String placeId) async {
    final profile = await getPassengerProfile(uid);
    if (profile != null) {
      final updatedPlaces = profile.favoritePlaces
          .where((p) => p['id'] != placeId)
          .toList();
      await _firestore.collection('passengers').doc(uid).update({
        'favoritePlaces': updatedPlaces,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> updateWalletBalance(String uid, double amount) async {
    await _firestore.collection('passengers').doc(uid).update({
      'walletBalance': FieldValue.increment(amount),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
