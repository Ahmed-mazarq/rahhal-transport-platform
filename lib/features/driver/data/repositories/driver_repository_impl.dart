import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/driver_profile.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/driver_payment_method.dart';
import '../../domain/models/working_area.dart';
import '../../domain/models/driver_stats.dart';
import '../../domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  final FirebaseFirestore _firestore;

  DriverRepositoryImpl(this._firestore);

  @override
  Future<DriverProfile?> getDriverProfile(String driverId) async {
    var doc = await _firestore.collection('drivers').doc(driverId).get();

    if (!doc.exists) {
      doc = await _firestore.collection('users').doc(driverId).get();
      if (!doc.exists) return null;
    }

    final rawData = doc.data()!;

    try {
      return DriverProfile.fromJson({'id': doc.id, ...rawData});
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('DriverProfile.fromJson exception: $e\n$stack');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateDriverProfile(DriverProfile profile) async {
    await _firestore
        .collection('drivers')
        .doc(profile.id)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateOnlineStatus(String driverId, bool isOnline) async {
    await _firestore.collection('drivers').doc(driverId).set({
      'isOnline': isOnline,
      'lastOnline': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> addPaymentMethod(String driverId, PaymentMethod method) async {
    final profile = await getDriverProfile(driverId);
    if (profile == null) return;

    final updatedMethods = List<PaymentMethod>.from(profile.paymentMethods);
    updatedMethods.add(method);

    await _firestore.collection('drivers').doc(driverId).set({
      'paymentMethods': updatedMethods.map((e) => e.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePaymentMethod(
    String driverId,
    PaymentMethod method,
  ) async {
    final profile = await getDriverProfile(driverId);
    if (profile == null) return;

    final updatedMethods = profile.paymentMethods.map((e) {
      return e.id == method.id ? method : e;
    }).toList();

    await _firestore.collection('drivers').doc(driverId).set({
      'paymentMethods': updatedMethods.map((e) => e.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removePaymentMethod(String driverId, String methodId) async {
    final profile = await getDriverProfile(driverId);
    if (profile == null) return;

    final updatedMethods = profile.paymentMethods
        .where((e) => e.id != methodId)
        .toList();

    await _firestore.collection('drivers').doc(driverId).set({
      'paymentMethods': updatedMethods.map((e) => e.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setPrimaryVehicle(String driverId, String vehicleId) async {
    final batch = _firestore.batch();

    // Update driver profile with primary vehicle mapping
    batch.set(_firestore.collection('drivers').doc(driverId), {
      'primaryVehicleId': vehicleId,
      'vehicleId': vehicleId,
    }, SetOptions(merge: true));

    // Update vehicles collection to ensure exactly one isDefault = true
    final vehiclesQuery = await _firestore
        .collection('vehicles')
        .where('driverId', isEqualTo: driverId)
        .get();

    for (var doc in vehiclesQuery.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == vehicleId});
    }

    await batch.commit();
  }

  @override
  Future<void> updateWorkingAreas(
    String driverId,
    List<WorkingArea> areas,
  ) async {
    await _firestore.collection('drivers').doc(driverId).set({
      'workingAreas': areas.map((e) => e.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  @override
  Future<DriverStats> getDriverStatistics(String driverId) async {
    final doc = await _firestore.collection('drivers').doc(driverId).get();
    if (!doc.exists) return const DriverStats();

    final data = doc.data()!;
    if (data.containsKey('statistics')) {
      return DriverStats.fromJson(data['statistics'] as Map<String, dynamic>);
    }
    return const DriverStats();
  }

  @override
  Future<void> updateDriverProfileImage(
    String driverId,
    String imageUrl,
    int updatedAt,
  ) async {
    final updates = {
      'profileImage': imageUrl,
      'profileImageUpdatedAt': updatedAt,
    };

    await _firestore
        .collection('drivers')
        .doc(driverId)
        .set(updates, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(driverId)
        .set(updates, SetOptions(merge: true));
  }

  @override
  Future<void> updateDriverProfileInfo(
    String driverId,
    String fullName,
    String bio,
    String country,
    String emergencyContact,
  ) async {
    final updates = {
      'fullName': fullName,
      'bio': bio,
      'country': country,
      'emergencyContact': emergencyContact,
    };

    // Update only the text fields without touching profileImage
    await _firestore
        .collection('drivers')
        .doc(driverId)
        .set(updates, SetOptions(merge: true));

    // Keep user's full name in sync
    await _firestore.collection('users').doc(driverId).set({
      'fullName': fullName,
      'name': fullName,
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<DriverPaymentMethod>> watchDriverPaymentMethods(String driverId) {
    return _firestore
        .collection('driver_payment_methods')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    DriverPaymentMethod.fromJson(doc.data()..['id'] = doc.id),
              )
              .toList(),
        );
  }

  @override
  Future<void> saveDriverPaymentMethod(DriverPaymentMethod method) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || method.driverId != currentUid) {
      throw Exception(
        'Unauthorized: Cannot modify payment methods for another driver',
      );
    }

    final data = {
      'driverId': method.driverId,
      'type': method.type,
      'providerName': method.providerName,
      'country': method.country,
      'currency': method.currency,
      'accountNumber': method.accountNumber,
      'accountHolderName': method.accountHolderName,
      'iban': method.iban,
      'isActive': method.isActive,
      'approvalStatus': 'not_required',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (method.id.isNotEmpty) {
      await _firestore
          .collection('driver_payment_methods')
          .doc(method.id)
          .update(data);
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('driver_payment_methods').add(data);
    }
  }

  @override
  Future<void> deleteDriverPaymentMethod(String methodId) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final doc =
        await _firestore.collection('driver_payment_methods').doc(methodId).get();
    if (doc.exists && currentUid != null) {
      if (doc.data()?['driverId'] != currentUid) {
        throw Exception(
          'Unauthorized: Cannot delete payment method for another driver',
        );
      }
    }
    await _firestore
        .collection('driver_payment_methods')
        .doc(methodId)
        .delete();
  }

  @override
  Future<void> toggleDriverPaymentMethodActive(
    String methodId,
    bool isActive,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final doc =
        await _firestore.collection('driver_payment_methods').doc(methodId).get();
    if (doc.exists && currentUid != null) {
      if (doc.data()?['driverId'] != currentUid) {
        throw Exception(
          'Unauthorized: Cannot update payment method for another driver',
        );
      }
    }
    await _firestore.collection('driver_payment_methods').doc(methodId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
