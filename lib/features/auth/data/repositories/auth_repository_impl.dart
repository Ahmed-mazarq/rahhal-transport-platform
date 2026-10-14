import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../../core/services/fcm_service.dart';

import '../../../common/models/user_model.dart';
import '../../../common/models/driver_model.dart';
import '../../../common/models/company_model.dart';
import '../../../passenger/domain/models/passenger_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  AuthRepositoryImpl(this._firestore, this._auth);

  @override
  Future<UserModel?> signIn(String phone, String password) async {
    try {
      final hiddenEmail = '$phone@rahal.app';

      // Check if user exists & is blocked in Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = UserModel.fromFirestore(
          userQuery.docs.first.data(),
          userQuery.docs.first.id,
        );
        if (userData.status == 'blocked') {
          throw Exception('تم حظر حسابك من قبل إدارة رحال.');
        } else if (userData.status == 'deleted') {
          throw Exception('accountNotFound');
        }
      } else {
        throw Exception('accountNotFound');
      }

      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: hiddenEmail,
          password: password,
        );

        final uid = credential.user!.uid;
        // Update lastLogin
        await _firestore.collection('users').doc(uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final user = await getCurrentUser(uid);

        if (user != null) {
          if (user.role == 'admin') {
            try {
              final tokenResult = await _auth.currentUser?.getIdTokenResult(
                true,
              );
              if (tokenResult != null) {
                final claims = tokenResult.claims ?? {};
                developer.log(
                  'Admin token refreshed: '
                  'role=${claims['role']}, '
                  'admin=${claims['admin']}, '
                  'app_role=${claims['app_role']}',
                );
              }
            } catch (e) {
              developer.log('Failed to refresh admin token: $e');
            }
          }

          if (user.role == 'driver') {
            final driverDoc = await _firestore
                .collection('drivers')
                .doc(uid)
                .get();
            if (!driverDoc.exists) {
              await _auth.signOut();
              throw Exception(
                'accountNotFound',
              ); // No driver record found, data inconsistent
            }

            final driverStatus = driverDoc.data()?['status'] ?? '';

            if (user.status != 'approved' || driverStatus != 'approved') {
              if (user.status == 'registering' ||
                  driverStatus == 'registering') {
                // DO NOT SIGN OUT - Router will send them to /signup-driver to finish
              } else if (user.status == 'pending_review' ||
                  driverStatus == 'pending_review') {
                // DO NOT SIGN OUT - Router will send them to /pending-approval
              } else if (user.status == 'need_modification' ||
                  driverStatus == 'need_modification') {
                // DO NOT SIGN OUT - Router will send them to /need-modification
              } else if (user.status == 'rejected' ||
                  driverStatus == 'rejected') {
                await _auth.signOut();
                throw Exception('REDIRECT:/rejected-account');
              } else {
                await _auth.signOut();
                throw Exception('حسابك غير مفعل بعد.');
              }
            }
          } else if (user.role == 'company') {
            final companyDoc = await _firestore
                .collection('companies')
                .doc(uid)
                .get();
            if (!companyDoc.exists) {
              await _auth.signOut();
              throw Exception('accountNotFound'); // No company record found
            }

            final companyStatus = companyDoc.data()?['status'] ?? '';

            if (user.status != 'approved' || companyStatus != 'approved') {
              if (user.status == 'registering' ||
                  companyStatus == 'registering') {
                // DO NOT SIGN OUT - Router will send them to /signup-company to finish
              } else if (user.status == 'pending_review' ||
                  companyStatus == 'pending_review') {
                // DO NOT SIGN OUT - Router will send them to /pending-approval
              } else if (user.status == 'need_modification' ||
                  companyStatus == 'need_modification') {
                // DO NOT SIGN OUT - Router will send them to /need-modification
              } else if (user.status == 'rejected' ||
                  companyStatus == 'rejected') {
                await _auth.signOut();
                throw Exception('REDIRECT:/rejected-account');
              } else {
                await _auth.signOut();
                throw Exception('حسابك غير مفعل بعد.');
              }
            }
          }
        }

        return user;
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw Exception('invalidCredentials');
        } else if (e.code == 'user-not-found') {
          throw Exception('accountNotFound');
        } else if (e.code == 'user-disabled') {
          throw Exception('تم حظر حسابك من قبل إدارة رحال.');
        } else if (e.code == 'network-request-failed') {
          throw Exception('networkError');
        } else {
          throw Exception('unknownError');
        }
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('invalidCredentials');
      } else if (e.code == 'network-request-failed') {
        throw Exception('networkError');
      } else {
        throw Exception('unknownError');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw Exception('networkError');
      }
      throw Exception('unknownError');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == 'accountNotFound' ||
          msg == 'تم حظر حسابك من قبل إدارة رحال.' ||
          msg == 'invalidCredentials' ||
          msg == 'networkError' ||
          msg == 'unknownError' ||
          msg.startsWith('REDIRECT:') ||
          msg.startsWith('طلب التسجيل لم يكتمل') ||
          msg.startsWith('حسابك غير مفعل بعد')) {
        throw Exception(msg);
      }
      throw Exception('unknownError');
    }
  }

  @override
  Future<UserModel?> signUp({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    Map<String, dynamic>? roleFields,
  }) async {
    debugPrint('SIGNUP DEBUG A: creating Firebase Auth user');
    try {
      final hiddenEmail = '$phone@rahal.app';

      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: hiddenEmail,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('auth_timeout');
            },
          );

      final uid = credential.user!.uid;
      debugPrint('SIGNUP DEBUG B: Firebase Auth created UID=$uid');

      final user = UserModel(
        id: uid,
        name: fullName,
        phone: phone,
        email: hiddenEmail,
        status: (role == 'driver' || role == 'company')
            ? 'registering'
            : 'active',
        walletBalance: 0.0,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      try {
        debugPrint('SIGNUP DEBUG C: writing users/$uid');
        final batch = _firestore.batch();
        batch.set(_firestore.collection('users').doc(uid), user.toFirestore());

        if (role == 'passenger') {
          final passengerProfile = PassengerProfile(
            uid: uid,
            favoriteDrivers: const [],
            favoritePlaces: const [],
            walletBalance: 0.0,
            tripCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            status: 'active',
          );
          batch.set(
            _firestore.collection('passengers').doc(uid),
            passengerProfile.toJson(),
          );
        }

        debugPrint('SIGNUP DEBUG D: committing Firestore batch');
        await batch.commit().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('firestore_timeout');
          },
        );

        debugPrint('SIGNUP DEBUG E: Firestore commit successful');
        debugPrint('SIGNUP DEBUG F: returning UserModel');
        return user;
      } catch (e, stack) {
        debugPrint('Firestore Batch Error: $e\n$stack');
        await credential.user?.delete().catchError((_) {});
        rethrow;
      }
    } on TimeoutException catch (_) {
      throw Exception(
        'تعذر الاتصال بخدمة التسجيل. تحقق من الإنترنت وحاول مرة أخرى.',
      );
    } on fb_auth.FirebaseAuthException catch (e, stack) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}\n$stack');
      rethrow;
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException: ${e.code} - ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown Error: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الخروج');
    }
  }

  @override
  Stream<UserModel?> watchAuthState() {
    late StreamController<UserModel?> controller;
    StreamSubscription? authSub;
    StreamSubscription? firestoreSub;

    controller = StreamController<UserModel?>(
      onListen: () async {
        authSub = _auth.authStateChanges().listen((fbUser) async {
          await firestoreSub?.cancel();

          if (fbUser == null) {
            controller.add(null);
            return;
          }

          firestoreSub = _firestore
              .collection('users')
              .doc(fbUser.uid)
              .snapshots()
              .listen((doc) async {
                if (doc.exists && doc.data() != null) {
                  final user = UserModel.fromFirestore(doc.data()!, doc.id);
                  try {
                    final fcmService = FCMService();
                    await fcmService.saveTokenToDatabase(user.id);
                  } catch (_) {}
                  controller.add(user);
                } else {
                  controller.add(null);
                }
              });
        });
      },
      onCancel: () {
        authSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<bool> isPhoneUnique(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .where('status', isNotEqualTo: 'deleted')
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e, stack) {
      developer.log('Error in isPhoneUnique: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<UserModel?> getCurrentUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل بيانات المستخدم');
    }
  }

  @override
  Future<PassengerProfile?> getPassengerProfile(String uid) async {
    try {
      final doc = await _firestore.collection('passengers').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return PassengerProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الملف الشخصي');
    }
  }

  @override
  Future<DriverModel?> getDriverProfile(String uid) async {
    try {
      final doc = await _firestore.collection('drivers').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return DriverModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل ملف الكابتن');
    }
  }

  @override
  Future<CompanyModel?> getCompanyProfile(String uid) async {
    try {
      final doc = await _firestore.collection('companies').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return CompanyModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل ملف الشركة');
    }
  }

  @override
  Future<void> updateDriverOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection('drivers').doc(uid).update({
        'isOnline': isOnline,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث حالة الاتصال');
    }
  }

  @override
  Future<void> updateDriverProfile(DriverModel driver) async {
    try {
      await _firestore
          .collection('drivers')
          .doc(driver.id)
          .set(driver.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث ملف الكابتن');
    }
  }

  @override
  Future<void> updateCompanyOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection('companies').doc(uid).update({
        'isOnline': isOnline,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث حالة اتصال الشركة');
    }
  }

  @override
  Future<void> updateCompanyProfile(CompanyModel profile) async {
    try {
      await _firestore
          .collection('companies')
          .doc(profile.id)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث بيانات الشركة');
    }
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث بيانات المستخدم');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('المستخدم غير مسجل الدخول');

      final credential = fb_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );

      await currentUser.reauthenticateWithCredential(credential);
      await currentUser.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('كلمة المرور الحالية غير صحيحة');
      } else {
        throw Exception('حدث خطأ أثناء تغيير كلمة المرور: ${e.message}');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('كلمة المرور الحالية غير صحيحة')) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء تغيير كلمة المرور');
    }
  }
}
