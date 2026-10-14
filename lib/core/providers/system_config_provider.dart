import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/data/repositories/admin_system_repository.dart';
import '../../features/admin/domain/models/admin_system_settings.dart';

final systemConfigRepositoryProvider = Provider<AdminSystemRepository>((ref) {
  return AdminSystemRepository();
});

final appSettingsProvider = StreamProvider<AdminSystemSettings>((ref) {
  final repo = ref.watch(systemConfigRepositoryProvider);
  return repo.watchAppSettings();
});

final featureFlagsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(systemConfigRepositoryProvider);
  return repo.streamFeatureFlags();
});
