import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/utils/exception_handler.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  final String _collectionPath;
  final String _cacheKey;

  SettingsRepositoryImpl(
    this._firestore,
    this._prefs, {
    required String collectionPrefix,
  }) : _collectionPath = '${collectionPrefix}_settings',
       _cacheKey = '${collectionPrefix}_settings_cache';

  @override
  Future<AppSettings?> getSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionPath)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        final settings = AppSettings.fromJson(doc.data()!);
        _cacheSettings(settings);
        return settings;
      }
      return null;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> updateSettings(String userId, AppSettings settings) async {
    try {
      final data = settings.toJson();
      data['lastUpdated'] = FieldValue.serverTimestamp();

      // If it's a new document, add createdAt
      final docRef = _firestore.collection(_collectionPath).doc(userId);
      final doc = await docRef.get();
      if (!doc.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
      _cacheSettings(settings);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Stream<AppSettings?> watchSettings(String userId) {
    return _firestore.collection(_collectionPath).doc(userId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        final settings = AppSettings.fromJson(snapshot.data()!);
        _cacheSettings(settings);
        return settings;
      }
      return null;
    });
  }

  @override
  AppSettings? getCachedSettings() {
    final cached = _prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = json.decode(cached) as Map<String, dynamic>;
        return AppSettings.fromJson(decoded);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _cacheSettings(AppSettings settings) {
    _prefs.setString(_cacheKey, json.encode(settings.toJson()));
  }

  @override
  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
  }
}
