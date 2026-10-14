import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

final localeProvider = Provider<Locale>((ref) {
  final lang = ref.watch(settingsProvider.select((s) => s.language));
  return Locale(lang);
});
