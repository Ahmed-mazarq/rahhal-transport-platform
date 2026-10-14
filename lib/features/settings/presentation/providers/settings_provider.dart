import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;
  final String? _userId;
  StreamSubscription<AppSettings?>? _subscription;

  AppSettingsNotifier(this._repository, this._userId)
    : super(const AppSettings()) {
    _init();
  }

  void _init() {
    // 1. Try cache first
    final cached = _repository.getCachedSettings();
    if (cached != null) {
      state = cached;
    }

    // 2. If logged in, stream from Firestore and manage topics
    if (_userId != null) {
      _subscription = _repository.watchSettings(_userId).listen((settings) {
        if (!mounted) return;
        if (settings != null) {
          state = settings;
          _syncFcmTopics(settings);
        } else {
          // Document might not exist yet, let's create a default one
          _repository.updateSettings(_userId, state);
        }
      });
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    if (_userId != null) {
      await _repository.updateSettings(_userId, newSettings);
      _syncFcmTopics(newSettings);
    }
  }

  Future<void> _syncFcmTopics(AppSettings settings) async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (settings.bookingNotifications) {
        await messaging.subscribeToTopic('booking_updates');
      } else {
        await messaging.unsubscribeFromTopic('booking_updates');
      }

      if (settings.systemNotifications) {
        await messaging.subscribeToTopic('system_alerts');
      } else {
        await messaging.unsubscribeFromTopic('system_alerts');
      }

      if (settings.offersNotifications) {
        await messaging.subscribeToTopic('offers');
      } else {
        await messaging.unsubscribeFromTopic('offers');
      }
    } catch (e) {
      // Ignore if on unsupported platform or no token
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final settingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      final repository = ref.watch(settingsRepositoryProvider);
      final authState = ref.watch(authProvider);
      String? userId;
      if (authState is Authenticated) {
        userId = authState.user.uid;
      }
      return AppSettingsNotifier(repository, userId);
    });
