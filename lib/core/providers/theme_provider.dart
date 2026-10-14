import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import 'package:rahal/core/providers/repository_providers.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  final authState = ref.watch(authProvider);

  // If user is not authenticated (e.g. login, splash, role selector),
  // Auth screens must always use Light theme (Part 3).
  if (authState is! Authenticated) {
    return ThemeMode.light;
  }

  final role = authState.user.role;
  final prefs = ref.watch(sharedPreferencesProvider);

  // Read ONLY the matching cache for the current authenticated role (Part 1)
  String cacheKey;
  if (role == 'driver') {
    cacheKey = 'driver_settings_cache';
  } else if (role == 'company') {
    cacheKey = 'company_settings_cache';
  } else {
    cacheKey = 'passenger_settings_cache';
  }

  final cachedData = prefs.getString(cacheKey);
  String themeStr = 'system';

  if (cachedData != null) {
    try {
      final decoded = json.decode(cachedData) as Map<String, dynamic>;
      themeStr = decoded['theme'] as String? ?? 'system';
    } catch (_) {
      themeStr = 'system';
    }
  }

  // Also react to runtime changes from settingsProvider
  final runtimeThemeStr = ref.watch(settingsProvider.select((s) => s.theme));
  if (runtimeThemeStr.isNotEmpty && runtimeThemeStr != 'system') {
    themeStr = runtimeThemeStr;
  }

  // Part 2: Driver default theme = LIGHT
  // If Driver has not explicitly chosen dark or light (i.e. themeStr == 'system' or no cache),
  // Driver UI must open in LIGHT MODE. Do not use system dark mode as the initial Driver default.
  if (role == 'driver') {
    if (themeStr == 'dark') {
      return ThemeMode.dark;
    }
    // Explicit 'light', or default 'system' / unset for driver -> light
    return ThemeMode.light;
  }

  switch (themeStr) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    case 'system':
    default:
      return ThemeMode.system;
  }
});
