import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_analytics_repository.dart';
import '../../domain/models/admin_analytics_models.dart';

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>((
  ref,
) {
  return AdminAnalyticsRepository();
});

final analyticsDateRangeProvider = StateProvider<AnalyticsRange>((ref) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 30));
  return AnalyticsRange(start: start, end: now, label: 'آخر 30 يوماً');
});

final adminAnalyticsDashboardProvider =
    FutureProvider.autoDispose<AnalyticsDashboardData>((ref) async {
      final repo = ref.watch(adminAnalyticsRepositoryProvider);
      final range = ref.watch(analyticsDateRangeProvider);

      final results = await Future.wait([
        repo.getDashboardKPIs(range),
        repo.getTopRoutes(range),
      ]);

      final kpis = results[0] as DashboardKPIs;
      final topRoutes = results[1] as List<TopRoute>;

      return AnalyticsDashboardData(kpis: kpis, topRoutes: topRoutes);
    });
