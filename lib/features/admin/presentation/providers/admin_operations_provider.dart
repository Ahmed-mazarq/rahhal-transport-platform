import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_operations_repository.dart';

final adminOperationsRepositoryProvider = Provider<AdminOperationsRepository>((
  ref,
) {
  return AdminOperationsRepository();
});

// Generic state providers for search and filters in operations
final opsSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final opsFilterStatusProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final opsSelectedItemsProvider = StateProvider.autoDispose<List<String>>(
  (ref) => [],
);

class OpsCollectionParams {
  final String collection;
  final dynamic defaultStatus;
  final bool sortLocally;
  final String orderBy;
  final bool descending;
  final String statusField;

  OpsCollectionParams(
    this.collection, {
    this.defaultStatus,
    this.sortLocally = false,
    this.orderBy = 'createdAt',
    this.descending = true,
    this.statusField = 'status',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpsCollectionParams &&
          runtimeType == other.runtimeType &&
          collection == other.collection &&
          _compareStatus(defaultStatus, other.defaultStatus) &&
          sortLocally == other.sortLocally &&
          orderBy == other.orderBy &&
          descending == other.descending &&
          statusField == other.statusField;

  bool _compareStatus(dynamic a, dynamic b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(
    collection,
    defaultStatus is List ? Object.hashAll(defaultStatus) : defaultStatus,
    sortLocally,
    orderBy,
    descending,
    statusField,
  );
}

// Unified StreamProvider for any operations collection
final opsStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, OpsCollectionParams>((ref, params) {
      final repo = ref.watch(adminOperationsRepositoryProvider);
      final searchQuery = ref.watch(opsSearchQueryProvider);
      final filterStatus = ref.watch(opsFilterStatusProvider);

      return repo.streamCollection(
        params.collection,
        statusFilter: filterStatus ?? params.defaultStatus,
        statusField: params.statusField,
        searchQuery: searchQuery,
        sortLocally: params.sortLocally,
        orderBy: params.orderBy,
        descending: params.descending,
      );
    });

// Operations Home Dashboard Stats Provider
final opsDashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final repo = ref.watch(adminOperationsRepositoryProvider);

  final results = await Future.wait([
    repo.getCount('trips', statusFilter: ['running', 'active', 'started']),
    repo.getCount('bookings', statusFilter: ['pending', 'support_review']),
    repo.getCount('driver_documents', statusFilter: 'pending'),
    repo.getCount('vehicles', statusFilter: 'maintenance'),
    repo.getCount('support_tickets', statusFilter: 'open'),
    repo.getCount('reports', statusFilter: 'open'),
  ]);

  return {
    'running_trips': results[0],
    'pending_bookings': results[1],
    'pending_docs': results[2],
    'vehicles_maintenance': results[3],
    'open_tickets': results[4],
    'open_reports': results[5],
  };
});
