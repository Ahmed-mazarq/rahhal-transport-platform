import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rahal/features/common/models/user_model.dart';
import 'package:rahal/features/common/models/driver_model.dart';
import 'package:rahal/features/common/models/company_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/supabase_config.dart';

class AdminUsersRepository {
  final FirebaseFirestore _firestore;

  AdminUsersRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _updateAuthStatus(
    String uid,
    String action, {
    bool? disabled,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    try {
      final body = <String, dynamic>{'action': action, 'targetUid': uid};
      if (disabled != null) {
        body['disabled'] = disabled;
      }
      final response = await http.post(
        Uri.parse(
          '${SupabaseConfig.supabaseUrl}/functions/v1/admin-manage-user',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('Failed to update auth status: \${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error calling admin-manage-user: $e');
    }
  }

  Future<void> _createAuditRecord(
    String targetUid,
    String action,
    String description,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('audit_logs').add({
        'targetUid': targetUid,
        'actorUid': user.uid,
        'action': action,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to create audit record: $e');
    }
  }

  Stream<List<UserModel>> streamUsers({
    String? role,
    String? status,
    String? searchQuery,
    String orderBy = 'createdAt',
    bool descending = true,
  }) {
    Query query = _firestore.collection('users');

    if (role != null) {
      if (role == 'admin') {
        // Admins can be any role not passenger, driver, company (or specific admin roles)
        query = query.where(
          'role',
          whereIn: [
            'super_admin',
            'admin',
            'operations_manager',
            'support_manager',
            'fleet_manager',
            'finance_manager',
            'compliance_manager',
            'analytics_manager',
            'read_only',
          ],
        );
      } else {
        query = query.where('role', isEqualTo: role);
      }
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    // Sort
    query = query.orderBy(orderBy, descending: descending);

    // Note: True realtime search in Firestore on partial strings is hard.
    // We use a prefix approach for exact match or prefix if needed, but since we are ordering by createdAt,
    // inequality filters on 'name' would conflict with orderBy unless indexed.
    // For enterprise apps without Algolia, we stream the subset and filter client-side if a query exists.
    query = query.limit(200); // Increased limit for client-side filtering

    return query.snapshots().map((snapshot) {
      var users = snapshot.docs.map((doc) {
        return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        users = users.where((user) {
          final name = user.name.toLowerCase();
          final phone = user.phone.toLowerCase();
          final email = user.email.toLowerCase();
          final uid = user.id.toLowerCase();

          return name.contains(q) ||
              phone.contains(q) ||
              email.contains(q) ||
              uid.contains(q);
        }).toList();
      }

      return users;
    });
  }

  Future<void> updateUserStatus(
    String uid,
    String status, {
    String? rejectedReason,
    List<String>? modificationChecklist,
    List<Map<String, dynamic>>? approvalHistory,
    String? blockReason,
    int? suspensionHours,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'blocked') {
      updateData['blockReason'] = blockReason;
      await _updateAuthStatus(uid, 'set_disabled_status', disabled: true);
    } else if (status == 'suspended') {
      updateData['suspensionReason'] = blockReason;
      if (suspensionHours != null) {
        updateData['suspendedUntil'] = DateTime.now()
            .add(Duration(hours: suspensionHours))
            .toIso8601String();
      }
      await _updateAuthStatus(uid, 'set_disabled_status', disabled: true);
    } else if (status == 'active' || status == 'approved') {
      updateData['blockReason'] = FieldValue.delete();
      updateData['suspensionReason'] = FieldValue.delete();
      updateData['suspendedUntil'] = FieldValue.delete();
      await _updateAuthStatus(uid, 'set_disabled_status', disabled: false);
    }

    if (status == 'rejected') {
      updateData['rejectedReason'] = rejectedReason;
      updateData['modificationChecklist'] = FieldValue.delete();
    } else if (status == 'approved') {
      updateData['rejectedReason'] = FieldValue.delete();
      updateData['modificationChecklist'] = FieldValue.delete();
      updateData['approvedAt'] = FieldValue.serverTimestamp();
      updateData['reviewedAt'] = FieldValue.serverTimestamp();
      if (FirebaseAuth.instance.currentUser != null) {
        updateData['approvedBy'] = FirebaseAuth.instance.currentUser!.uid;
        updateData['reviewedBy'] = FirebaseAuth.instance.currentUser!.uid;
      }
    } else if (status == 'need_modification') {
      updateData['rejectedReason'] = rejectedReason;
      updateData['reviewedAt'] = FieldValue.serverTimestamp();
      if (FirebaseAuth.instance.currentUser != null) {
        updateData['reviewedBy'] = FirebaseAuth.instance.currentUser!.uid;
      }
    }

    if (modificationChecklist != null) {
      updateData['modificationChecklist'] = modificationChecklist;
    }

    if (approvalHistory != null) {
      updateData['approvalHistory'] = approvalHistory;
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final role = userDoc.data()?['role'];

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(uid),
      updateData,
      SetOptions(merge: true),
    );

    if (role == 'driver') {
      final driverData = <String, dynamic>{
        'status': status,
        'isVerified': status == 'approved',
      };
      batch.set(
        _firestore.collection('drivers').doc(uid),
        driverData,
        SetOptions(merge: true),
      );

      // Fix #4: Account approval synchronizes document approval safely
      if (status == 'approved') {
        final driverDocsSnapshot = await _firestore
            .collection('driver_documents')
            .where('driverId', isEqualTo: uid)
            .get();
        for (var doc in driverDocsSnapshot.docs) {
          final docStatus = doc.data()['status'];
          // Only approve pending or missing status, don't override explicitly rejected or needs_update
          if (docStatus == null ||
              docStatus == 'pending' ||
              docStatus == 'missing') {
            batch.set(doc.reference, {
              'status': 'approved',
            }, SetOptions(merge: true));
          }
        }
      }
    } else if (role == 'company') {
      final compData = <String, dynamic>{
        'status': status,
        'isVerified': status == 'approved',
      };
      batch.set(
        _firestore.collection('companies').doc(uid),
        compData,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> updateDocumentStatus({
    required String uid,
    required String role,
    required String documentKey,
    required String status,
    String notes = '',
  }) async {
    final collection = role == 'driver' ? 'drivers' : 'companies';

    final batch = _firestore.batch();

    batch.set(_firestore.collection(collection).doc(uid), {
      'documents.$documentKey.status': status,
      'documents.$documentKey.notes': notes,
      'documents.$documentKey.updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Fix #10: Admin document approval syncs with driver_documents collection
    if (role == 'driver') {
      final driverDocsSnapshot = await _firestore
          .collection('driver_documents')
          .where('driverId', isEqualTo: uid)
          .where('type', isEqualTo: documentKey)
          .get();

      for (var doc in driverDocsSnapshot.docs) {
        batch.set(doc.reference, {
          'status': status,
          'adminNotes': notes,
          'lastUpdated':
              FieldValue.serverTimestamp(), // or DateTime.now().toIso8601String() depending on schema, but DriverDocument handles both
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<void> bulkUpdateStatus(List<String> uids, String status) async {
    final batch = _firestore.batch();
    for (var uid in uids) {
      final ref = _firestore.collection('users').doc(uid);
      batch.set(ref, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (status == 'blocked' || status == 'suspended') {
        await _updateAuthStatus(uid, 'set_disabled_status', disabled: true);
      } else if (status == 'active') {
        await _updateAuthStatus(uid, 'set_disabled_status', disabled: false);
      }
    }
    await batch.commit();
  }

  Future<void> updateUserManagementStatus(
    String uid,
    String status, {
    String? blockReason,
    int? suspensionHours,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'blocked') {
      updateData['blockReason'] = blockReason;
      await _updateAuthStatus(uid, 'set_disabled_status', disabled: true);
    } else if (status == 'suspended') {
      updateData['suspensionReason'] = blockReason;
      if (suspensionHours != null) {
        updateData['suspendedUntil'] = DateTime.now()
            .add(Duration(hours: suspensionHours))
            .toIso8601String();
      }
      await _updateAuthStatus(uid, 'set_disabled_status', disabled: true);
    } else if (status == 'active') {
      updateData['blockReason'] = FieldValue.delete();
      updateData['suspensionReason'] = FieldValue.delete();
      updateData['suspendedUntil'] = FieldValue.delete();
      await _updateAuthStatus(uid, 'set_disabled_status', disabled: false);
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(updateData, SetOptions(merge: true));
    await _createAuditRecord(
      uid,
      'USER_STATUS_UPDATED',
      'Updated status to $status',
    );
  }

  Future<void> deleteUserSafely(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateAuthStatus(uid, 'set_disabled_status', disabled: true);
    await _createAuditRecord(uid, 'USER_DELETED', 'Soft deleted user');
  }

  Future<void> deleteUser(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return;
    final role = userDoc.data()?['role'];

    final batch = _firestore.batch();

    // Soft delete in users collection
    batch.set(_firestore.collection('users').doc(uid), {
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _updateAuthStatus(uid, 'set_disabled_status');

    // Hard delete related data based on role
    if (role == 'driver') {
      batch.delete(_firestore.collection('drivers').doc(uid));
      // Delete vehicles associated with this driver
      final vehicles = await _firestore
          .collection('vehicles')
          .where('driverId', isEqualTo: uid)
          .get();
      for (var doc in vehicles.docs) {
        batch.delete(doc.reference);
      }
    } else if (role == 'company') {
      batch.delete(_firestore.collection('companies').doc(uid));
      // Delete fleet/vehicles
      final vehicles = await _firestore
          .collection('vehicles')
          .where('companyId', isEqualTo: uid)
          .get();
      for (var doc in vehicles.docs) {
        batch.delete(doc.reference);
      }
    }

    // Delete notifications
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> bulkDeleteUsers(List<String> uids) async {
    for (var uid in uids) {
      await deleteUser(uid);
    }
  }

  Future<void> createAdminUser(Map<String, dynamic> adminData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('غير مسجل الدخول');
    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/admin-manage-user',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'action': 'create_sub_admin',
        'email': adminData['email'],
        'password': adminData['password'],
        'displayName': adminData['fullName'],
        'phone': adminData['phone'],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل إنشاء المستخدم في Auth: \${response.body}');
    }

    final responseData = jsonDecode(response.body);
    final String newUid = responseData['uid'];

    adminData.remove('password');
    adminData['uid'] = newUid;
    adminData['createdAt'] = FieldValue.serverTimestamp();
    adminData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(newUid).set(adminData);
    await _createAuditRecord(
      newUid,
      'ADMIN_CREATED',
      'Created subordinate admin',
    );
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<DriverModel?> getDriverById(String uid) async {
    final doc = await _firestore.collection('drivers').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return DriverModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<CompanyModel?> getCompanyById(String uid) async {
    final doc = await _firestore.collection('companies').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return CompanyModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateDriver(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('drivers')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateCompany(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('companies')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}
