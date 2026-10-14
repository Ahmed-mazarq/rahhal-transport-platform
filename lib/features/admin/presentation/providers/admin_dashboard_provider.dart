import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_dashboard_repository.dart';
import 'admin_unified_documents_provider.dart';
import '../../../../core/utils/logger.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((
  ref,
) {
  return AdminDashboardRepository();
});

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((
  ref,
) async {
  final repository = ref.watch(adminDashboardRepositoryProvider);
  final stats = await repository.getDashboardStats();

  // Replace the pending count with the unified/real source if it's available
  // To avoid awaiting the stream which might not emit if offline, we can check its current value
  // Or just await the first value of the stream.
  try {
    final unifiedDocs = await ref.read(
      adminUnifiedDocumentsStreamProvider.future,
    );
    final realPendingCount = unifiedDocs
        .where(
          (doc) =>
              !doc.isMissing &&
              doc.documentUrl.isNotEmpty &&
              (doc.documentStatus == 'pending' ||
                  doc.documentStatus == 'uploaded'),
        )
        .length;

    return AdminDashboardStats(
      totalPassengers: stats.totalPassengers,
      totalDrivers: stats.totalDrivers,
      totalCompanies: stats.totalCompanies,
      totalVehicles: stats.totalVehicles,
      totalTrips: stats.totalTrips,
      totalBookings: stats.totalBookings,
      pendingDocuments: realPendingCount,
      openTickets: stats.openTickets,
      totalReports: stats.totalReports,
      activeTrips: stats.activeTrips,
      todaysTrips: stats.todaysTrips,
      onlineDrivers: stats.onlineDrivers,
      activeCompanies: stats.activeCompanies,
      averageRating: stats.averageRating,
      platformGrowth: stats.platformGrowth,
      lastUpdated: stats.lastUpdated,
    );
  } catch (e, st) {
    appLogger.e(
      'Failed to get real pending documents count for dashboard',
      error: e,
      stackTrace: st,
    );
    // Fallback to the repository's count if stream fails
    return stats;
  }
});
