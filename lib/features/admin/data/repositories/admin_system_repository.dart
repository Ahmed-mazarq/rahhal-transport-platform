import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/admin_system_settings.dart';

class AdminSystemRepository {
  final FirebaseFirestore _firestore;

  AdminSystemRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Generic stream for system collections (Audit Logs, Geo Data, CMS content, Security events)
  Stream<List<Map<String, dynamic>>> streamSystemCollection(
    String collection, {
    String? typeFilter,
    String typeField = 'type',
    int limit = 200,
    String orderBy = 'createdAt',
    bool descending = true,
  }) {
    Query query = _firestore.collection(collection);

    if (typeFilter != null && typeFilter.isNotEmpty) {
      query = query.where(typeField, isEqualTo: typeFilter);
    }

    query = query.orderBy(orderBy, descending: descending);
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // System Health Monitoring
  Stream<Map<String, dynamic>> streamSystemHealth() {
    // In a real app, this would be written by a cloud function or backend service to a single document.
    return _firestore
        .collection('system_config')
        .doc('health_status')
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return {
              'status': 'degraded',
              'firestore_latency': 0,
              'memory_usage': 0,
              'active_sessions': 0,
            };
          }
          return doc.data() as Map<String, dynamic>;
        });
  }

  // Settings
  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _firestore
        .collection('system_config')
        .doc('app_settings')
        .set(settings, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> streamSystemSettings() {
    return _firestore
        .collection('system_config')
        .doc('app_settings')
        .snapshots()
        .map((doc) {
          return doc.exists ? doc.data() as Map<String, dynamic> : {};
        });
  }

  Stream<AdminSystemSettings> watchAppSettings() {
    return _firestore
        .collection('system_config')
        .doc('app_settings')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return AdminSystemSettings.fromMap(doc.data()!);
          }
          return AdminSystemSettings(
            appName: 'رحّال',
            timezone: 'Asia/Riyadh',
            currency: 'SAR',
            maintenanceMode: false,
            maintenanceMessageAr: 'نظام رحّال تحت الصيانة حالياً',
            maintenanceMessageEn:
                'Rahhal system is currently under maintenance',
            allowAdminBypass: true,
            supportEmail: '',
            supportPhone: '',
            supportWhatsapp: '',
            schemaVersion: 2,
          );
        });
  }

  Future<void> updateAppSettings(
    AdminSystemSettings settings,
    String adminUid,
  ) async {
    final data = settings.toMap();
    data['updatedBy'] = adminUid;
    await _firestore
        .collection('system_config')
        .doc('app_settings')
        .set(data, SetOptions(merge: true));
  }

  // Feature Flags
  Future<void> updateFeatureFlag(String featureId, bool value) async {
    await _firestore.collection('system_config').doc('feature_flags').set({
      featureId: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> streamFeatureFlags() {
    return _firestore
        .collection('system_config')
        .doc('feature_flags')
        .snapshots()
        .map((doc) {
          return doc.exists ? doc.data() as Map<String, dynamic> : {};
        });
  }
}
