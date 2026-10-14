import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_system_repository.dart';

import '../../domain/models/admin_system_settings.dart';

final adminSystemRepositoryProvider = Provider<AdminSystemRepository>((ref) {
  return AdminSystemRepository();
});

// Settings & Configs
final systemSettingsProvider = StreamProvider.autoDispose<AdminSystemSettings>((
  ref,
) {
  return ref.watch(adminSystemRepositoryProvider).watchAppSettings();
});

final featureFlagsProvider = StreamProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(adminSystemRepositoryProvider).streamFeatureFlags();
});

final systemHealthProvider = StreamProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(adminSystemRepositoryProvider).streamSystemHealth();
});

// Generic Collection Streams
class SystemCollectionParams {
  final String collection;
  final String? typeFilter;
  final String typeField;

  SystemCollectionParams(
    this.collection, {
    this.typeFilter,
    this.typeField = 'type',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemCollectionParams &&
          runtimeType == other.runtimeType &&
          collection == other.collection &&
          typeFilter == other.typeFilter &&
          typeField == other.typeField;

  @override
  int get hashCode =>
      collection.hashCode ^ typeFilter.hashCode ^ typeField.hashCode;
}

final systemStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, SystemCollectionParams>((ref, params) {
      return ref
          .watch(adminSystemRepositoryProvider)
          .streamSystemCollection(
            params.collection,
            typeFilter: params.typeFilter,
            typeField: params.typeField,
          );
    });
