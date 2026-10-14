import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/driver_providers.dart';
import '../utils/driver_tokens.dart';

class DriverStatsScreen extends ConsumerWidget {
  const DriverStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(driverPerformanceProvider);
    final financeAsync = ref.watch(driverFinancialSummaryProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : DriverTokens.backgroundLight,
        appBar: AppBar(
          title: const Text(
            'مركز الأداء والإحصائيات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: isDark ? DriverTokens.cardDark : Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverPerformanceProvider);
            ref.invalidate(driverFinancialSummaryProvider);
          },
          color: DriverTokens.primaryNavy,
          child: performanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: DriverTokens.error,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تعذر تحميل بيانات الأداء',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(driverPerformanceProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
            data: (data) {
              final double completionRate = data['completionRate'] ?? 1.0;
              final double? acceptanceRate = data['acceptanceRate'];
              final int totalTrips = data['totalTrips'] ?? 0;
              final int completedTrips = data['completedTrips'] ?? 0;
              final int cancelledTrips = data['cancelledTrips'] ?? 0;
              final int? responseTime = data['responseTime'];
              final int passengerCount = data['passengerCount'] ?? 0;
              final int vehicleCount = data['vehicleCount'] ?? 0;
              final double? avgRating = data['avgRating'];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Hero Rating Card
                  _buildHeroRatingCard(isDark, avgRating, completedTrips),
                  const SizedBox(height: 16),

                  // 2. Financial Summary (Grouped by Currency)
                  financeAsync.when(
                    data: (finance) => _buildFinancialSection(isDark, finance),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // 3. Trips Performance Section
                  _buildSectionTitle('أداء الرحلات', isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'إجمالي الرحلات',
                          value: '$totalTrips',
                          icon: Icons.alt_route_rounded,
                          color: DriverTokens.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'الرحلات المكتملة',
                          value: '$completedTrips',
                          icon: Icons.task_alt_rounded,
                          color: DriverTokens.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'نسبة الإكمال',
                          value: '${(completionRate * 100).toInt()}%',
                          icon: Icons.check_circle_outline_rounded,
                          color: DriverTokens.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'رحلات ملغاة',
                          value: '$cancelledTrips',
                          icon: Icons.cancel_outlined,
                          color: cancelledTrips > 0
                              ? DriverTokens.error
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. Operations Section
                  _buildSectionTitle('مؤشرات الخدمة والعمليات', isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'الركاب المؤكدون',
                          value: '$passengerCount',
                          icon: Icons.people_outline_rounded,
                          color: DriverTokens.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'المركبات المسجلة',
                          value: '$vehicleCount',
                          icon: Icons.directions_car_filled_rounded,
                          color: DriverTokens.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'معدل القبول',
                          value: acceptanceRate != null
                              ? '${(acceptanceRate * 100).toInt()}%'
                              : 'غير متوفر',
                          icon: Icons.handshake_outlined,
                          color: DriverTokens.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          isDark,
                          title: 'متوسط الاستجابة',
                          value: responseTime != null
                              ? '$responseTime دقيقة'
                              : 'غير متوفر',
                          icon: Icons.timer_outlined,
                          color: DriverTokens.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : DriverTokens.primaryNavy,
      ),
    );
  }

  Widget _buildHeroRatingCard(bool isDark, double? rating, int completedTrips) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [DriverTokens.primaryNavy, const Color(0xFF16325B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DriverTokens.borderHero,
        boxShadow: DriverTokens.cardShadow(isDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: DriverTokens.accentGold,
                size: 40,
              ),
              const SizedBox(width: 10),
              Text(
                rating != null ? rating.toStringAsFixed(1) : 'جديد',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'تقييم السائق المعتمد',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Colors.greenAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'إجمالي $completedTrips رحلة مكتملة بنجاح',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(bool isDark, Map<String, double> finance) {
    if (finance.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('مبالغ التأكيد المستلمة', isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? DriverTokens.cardDark : Colors.white,
            borderRadius: DriverTokens.borderCard,
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: finance.entries.map((entry) {
              final currency = entry.key;
              final amount = entry.value;
              final currencyLabel = currency == 'YER'
                  ? 'ريال يمني'
                  : 'ريال سعودي';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: DriverTokens.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${amount.toStringAsFixed(0)} $currency',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DriverTokens.success,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DriverTokens.cardDark : Colors.white,
        borderRadius: DriverTokens.borderCard,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : DriverTokens.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}
