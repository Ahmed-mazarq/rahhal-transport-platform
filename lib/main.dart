// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rahal/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/repository_providers.dart';
import 'core/services/fcm_service.dart';
import 'core/utils/db_seeder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final app = Firebase.app();
  debugPrint('===== FIREBASE READY =====');
  debugPrint('App Name: ${app.name}');
  debugPrint('Project ID: ${app.options.projectId}');

  await SupabaseConfig.initialize();

  final fcmService = FCMService();
  await fcmService.initialize();
  debugPrint('===== FCM INITIALIZED =====');

  // Initialize Geographic master data (idempotent, won't overwrite existing)
  try {
    debugPrint('===== RUNNING GEO SEEDER =====');
    await DbSeeder.seedDatabase(FirebaseFirestore.instance);
  } catch (e) {
    debugPrint('Geo Seeder Error: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'رحال',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
