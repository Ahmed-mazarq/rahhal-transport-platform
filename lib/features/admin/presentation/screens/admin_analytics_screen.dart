import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../presentation/providers/admin_analytics_provider.dart';
import '../../domain/models/admin_analytics_models.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  Future<void> _exportCsv(
    AnalyticsDashboardData data,
    AnalyticsRange range,
  ) async {
    try {
      final kpis = data.kpis;
      final List<List<dynamic>> csvData = [
        ['تقرير تحليلات منصة رحال'],
        ['الفترة', range.label],
        ['من', DateFormat('yyyy-MM-dd').format(range.start)],
        ['إلى', DateFormat('yyyy-MM-dd').format(range.end)],
        [],
        ['الإحصائيات الشاملة'],
        ['إجمالي الركاب', kpis.totalPassengers],
        ['إجمالي السائقين', kpis.totalDrivers],
        ['إجمالي الشركات', kpis.totalCompanies],
        ['إجمالي المركبات', kpis.totalVehicles],
        ['إجمالي الرحلات', kpis.totalTrips],
        ['إجمالي الحجوزات', kpis.totalBookings],
        [],
        ['إحصائيات الفترة'],
        ['رحلات الفترة', kpis.periodTrips],
        ['حجوزات الفترة', kpis.periodBookings],
        ['الرحلات المكتملة', kpis.completedTrips],
        ['الرحلات الملغاة', kpis.cancelledTrips],
        ['الحجوزات المكتملة', kpis.completedBookings],
        ['الحجوزات الملغاة', kpis.cancelledBookings],
        ['معدل الإلغاء', '${kpis.cancellationRate.toStringAsFixed(1)}%'],
        ['معدل إشغال المقاعد', '${kpis.seatOccupancyRate.toStringAsFixed(1)}%'],
        ['متوسط تقييم السائقين', kpis.averageDriverRating.toStringAsFixed(1)],
        ['السائقين المتصلين', kpis.onlineDrivers],
        ['الشركات النشطة', kpis.activeCompanies],
        ['المستندات قيد المراجعة', kpis.pendingDocuments],
        ['تذاكر الدعم المفتوحة', kpis.openSupportTickets],
        [],
        ['متوسط أسعار الرحلات حسب العملة'],
      ];

      kpis.averageTripPriceByCurrency.forEach((currency, price) {
        csvData.add([currency, price.toStringAsFixed(2)]);
      });

      csvData.addAll([
        [],
        ['أشهر المسارات'],
        ['من', 'إلى', 'عدد الرحلات', 'الرحلات المكتملة'],
      ]);

      for (var route in data.topRoutes) {
        csvData.add([
          route.origin,
          route.destination,
          route.tripCount,
          route.completedTrips,
        ]);
      }

      final StringBuffer buffer = StringBuffer();
      for (final row in csvData) {
        final line = row
            .map((cell) {
              final str = cell == null ? '' : cell.toString();
              if (str.contains(',') ||
                  str.contains('"') ||
                  str.contains('\n')) {
                return '"${str.replaceAll('"', '""')}"';
              }
              return str;
            })
            .join(',');
        buffer.writeln(line);
      }
      final String csv = buffer.toString();
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/rahhal_analytics_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'تقرير تحليلات منصة رحال'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر تصدير التقرير')));
      }
    }
  }

  String _analyticsErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'failed-precondition':
          return 'تحتاج قاعدة البيانات إلى فهرس إضافي لتشغيل هذا التقرير.';
        case 'permission-denied':
          return 'لا توجد صلاحية كافية لقراءة بيانات التحليلات.';
        case 'unavailable':
          return 'تعذر الاتصال بقاعدة البيانات. تحقق من الاتصال.';
        default:
          return 'تعذر تحميل بيانات التحليلات.';
      }
    }
    return 'تعذر تحميل بيانات التحليلات.';
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminAnalyticsDashboardProvider);
    final range = ref.watch(analyticsDateRangeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'التحليلات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          _buildDateRangeSelector(context, ref, range),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(adminAnalyticsDashboardProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black87),
            tooltip: 'تصدير التقرير',
            onPressed: () {
              dashboardAsync.whenData((data) => _exportCsv(data, range));
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) => _buildBody(context, data, range),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري تحميل التحليلات...',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 64),
              const SizedBox(height: 16),
              const Text(
                'تعذر تحميل التحليلات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _analyticsErrorMessage(err),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(adminAnalyticsDashboardProvider),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    WidgetRef ref,
    AnalyticsRange currentRange,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.date_range, color: Colors.black87),
      tooltip: 'تغيير الفترة',
      onSelected: (val) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

        DateTime start;
        String label;

        if (val == 'custom') {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: now,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF0B1F3A),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            start = picked.start;
            final end = DateTime(
              picked.end.year,
              picked.end.month,
              picked.end.day,
              23,
              59,
              59,
            );
            label = 'فترة مخصصة';
            ref.read(analyticsDateRangeProvider.notifier).state =
                AnalyticsRange(start: start, end: end, label: label);
          }
          return;
        }

        switch (val) {
          case 'today':
            start = DateTime(now.year, now.month, now.day);
            label = 'اليوم';
            break;
          case '7':
            start = now.subtract(const Duration(days: 7));
            label = 'آخر 7 أيام';
            break;
          case '30':
            start = now.subtract(const Duration(days: 30));
            label = 'آخر 30 يوماً';
            break;
          case 'this_month':
            start = DateTime(now.year, now.month, 1);
            label = 'هذا الشهر';
            break;
          case 'current_quarter':
            final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
            start = DateTime(now.year, quarterMonth, 1);
            label = 'الربع الحالي';
            break;
          case 'this_year':
            start = DateTime(now.year, 1, 1);
            label = 'هذه السنة';
            break;
          default:
            start = now.subtract(const Duration(days: 30));
            label = 'آخر 30 يوماً';
        }

        ref.read(analyticsDateRangeProvider.notifier).state = AnalyticsRange(
          start: start,
          end: today,
          label: label,
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'today',
          child: Text('اليوم', style: TextStyle(fontFamily: 'Cairo')),
        ),
        const PopupMenuItem(
          value: '7',
          child: Text('آخر 7 أيام', style: TextStyle(fontFamily: 'Cairo')),
        ),
        const PopupMenuItem(
          value: '30',
          child: Text('آخر 30 يوماً', style: TextStyle(fontFamily: 'Cairo')),
        ),
        const PopupMenuItem(
          value: 'this_month',
          child: Text('هذا الشهر', style: TextStyle(fontFamily: 'Cairo')),
        ),
        const PopupMenuItem(
          value: 'current_quarter',
          child: Text('الربع الحالي', style: TextStyle(fontFamily: 'Cairo')),
        ),
        const PopupMenuItem(
          value: 'this_year',
          child: Text('هذه السنة', style: TextStyle(fontFamily: 'Cairo')),
        ),
        const PopupMenuItem(
          value: 'custom',
          child: Text('فترة مخصصة', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsDashboardData data,
    AnalyticsRange range,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التحليلات المتقدمة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'رؤية شاملة لأداء منصة رحّال',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الفترة المحددة: ${range.label} (${DateFormat('yyyy/MM/dd').format(range.start)} - ${DateFormat('yyyy/MM/dd').format(range.end)})',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.blueGrey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('المؤشرات الرئيسية (الإجمالي)'),
          const SizedBox(height: 16),
          _buildExecutiveSummary(data.kpis),

          const SizedBox(height: 32),
          _buildSectionTitle('مؤشرات الأداء (خلال الفترة)'),
          const SizedBox(height: 16),
          _buildPeriodMetrics(data.kpis),

          const SizedBox(height: 32),
          _buildSectionTitle('الإحصائيات التشغيلية (الحالية)'),
          const SizedBox(height: 16),
          _buildOperationalStats(data.kpis),

          if (data.kpis.averageTripPriceByCurrency.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionTitle('متوسط سعر الرحلات'),
            const SizedBox(height: 16),
            _buildAveragePrices(data.kpis.averageTripPriceByCurrency),
          ],

          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTripsChart(data.kpis)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildStatusPieCharts(data.kpis)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTripsChart(data.kpis),
                    const SizedBox(height: 24),
                    _buildStatusPieCharts(data.kpis),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildTopRoutes(data.topRoutes),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildExecutiveSummary(DashboardKPIs kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 4
            : (constraints.maxWidth >= 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              'إجمالي الركاب',
              '${kpis.totalPassengers}',
              kpis.passengersChange,
              Colors.blue,
              isNegativeMetric: false,
            ),
            _buildSummaryCard(
              'إجمالي السائقين',
              '${kpis.totalDrivers}',
              kpis.driversChange,
              Colors.green,
              isNegativeMetric: false,
            ),
            _buildSummaryCard(
              'إجمالي الشركات',
              '${kpis.totalCompanies}',
              kpis.companiesChange,
              Colors.orange,
              isNegativeMetric: false,
            ),
            _buildSummaryCard(
              'إجمالي المركبات',
              '${kpis.totalVehicles}',
              null,
              Colors.teal,
              isNegativeMetric: false,
            ),
            _buildSummaryCard(
              'إجمالي الرحلات',
              '${kpis.totalTrips}',
              null,
              Colors.purple,
              isNegativeMetric: false,
            ),
            _buildSummaryCard(
              'إجمالي الحجوزات',
              '${kpis.totalBookings}',
              null,
              Colors.indigo,
              isNegativeMetric: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodMetrics(DashboardKPIs kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 4
            : (constraints.maxWidth >= 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildSimpleStatCard(
              'الرحلات خلال الفترة',
              '${kpis.periodTrips}',
              Icons.directions_car,
              Colors.blue,
            ),
            _buildSimpleStatCard(
              'الحجوزات خلال الفترة',
              '${kpis.periodBookings}',
              Icons.book_online,
              Colors.purple,
            ),
            _buildSimpleStatCard(
              'الرحلات المكتملة',
              '${kpis.completedTrips}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildSimpleStatCard(
              'الرحلات الملغاة',
              '${kpis.cancelledTrips}',
              Icons.cancel,
              Colors.red,
            ),
            _buildSimpleStatCard(
              'الحجوزات المكتملة',
              '${kpis.completedBookings}',
              Icons.check_circle_outline,
              Colors.green,
            ),
            _buildSimpleStatCard(
              'الحجوزات الملغاة',
              '${kpis.cancelledBookings}',
              Icons.cancel_presentation,
              Colors.red,
            ),
            _buildSimpleStatCard(
              'معدل الإلغاء',
              '${kpis.cancellationRate.toStringAsFixed(1)}%',
              Icons.warning,
              Colors.orange,
            ),
            _buildSimpleStatCard(
              'معدل إشغال المقاعد',
              '${kpis.seatOccupancyRate.toStringAsFixed(1)}%',
              Icons.airline_seat_recline_normal,
              Colors.teal,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOperationalStats(DashboardKPIs kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 4
            : (constraints.maxWidth >= 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildSimpleStatCard(
              'السائقون المتصلون',
              '${kpis.onlineDrivers}',
              Icons.online_prediction,
              Colors.green,
            ),
            _buildSimpleStatCard(
              'الشركات النشطة',
              '${kpis.activeCompanies}',
              Icons.business,
              Colors.blue,
            ),
            _buildSimpleStatCard(
              'المستندات قيد المراجعة',
              '${kpis.pendingDocuments}',
              Icons.pending_actions,
              Colors.orange,
            ),
            _buildSimpleStatCard(
              'تذاكر الدعم المفتوحة',
              '${kpis.openSupportTickets}',
              Icons.support_agent,
              Colors.red,
            ),
            _buildSimpleStatCard(
              'متوسط تقييم السائقين',
              kpis.averageDriverRating.toStringAsFixed(1),
              Icons.star,
              Colors.amber,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAveragePrices(Map<String, double> prices) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: prices.entries.map((e) {
        return Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.value.toStringAsFixed(0),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    AnalyticsComparison? change,
    Color color, {
    required bool isNegativeMetric,
  }) {
    Widget? growthWidget;

    if (change != null) {
      if (change.isNew) {
        growthWidget = _buildGrowthBadge(
          'جديد',
          Colors.blue,
          Icons.new_releases,
        );
      } else {
        final pct = change.percentageChange;
        if (pct == 0.0) {
          growthWidget = _buildGrowthBadge(
            '0%',
            Colors.grey,
            Icons.horizontal_rule,
          );
        } else {
          final isIncrease = pct > 0;
          final pctStr = '${isIncrease ? '+' : ''}${pct.toStringAsFixed(1)}%';

          Color growthColor;
          if (isNegativeMetric) {
            growthColor = isIncrease ? Colors.red : Colors.green;
          } else {
            growthColor = isIncrease ? Colors.green : Colors.red;
          }

          final icon = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;
          growthWidget = _buildGrowthBadge(pctStr, growthColor, icon);
        }
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (growthWidget != null) growthWidget,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textDirection: ui.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsChart(DashboardKPIs kpis) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الرحلات والحجوزات (للفترة المحددة)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            if (kpis.periodTrips == 0 && kpis.periodBookings == 0)
              const SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'لا توجد بيانات خلال الفترة المحددة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              )
            else
              SizedBox(
                height: 250,
                width: double.infinity,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        (kpis.periodTrips > kpis.periodBookings
                                    ? kpis.periodTrips
                                    : kpis.periodBookings)
                                .toDouble() *
                            1.2 +
                        10,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            );
                            String text;
                            switch (value.toInt()) {
                              case 0:
                                text = 'الرحلات';
                                break;
                              case 1:
                                text = 'الحجوزات';
                                break;
                              default:
                                text = '';
                                break;
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(text, style: style),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: kpis.periodTrips.toDouble(),
                            color: Colors.blue,
                            width: 40,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: kpis.periodBookings.toDouble(),
                            color: Colors.purple,
                            width: 40,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieCharts(DashboardKPIs kpis) {
    final tripsOther =
        kpis.periodTrips - kpis.completedTrips - kpis.cancelledTrips;
    final bookingsOther =
        kpis.periodBookings - kpis.completedBookings - kpis.cancelledBookings;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع الحالات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'الرحلات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (kpis.periodTrips == 0)
                        const SizedBox(
                          height: 150,
                          child: Center(child: Text('لا بيانات')),
                        )
                      else
                        SizedBox(
                          height: 150,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: [
                                if (kpis.completedTrips > 0)
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: kpis.completedTrips.toDouble(),
                                    title: '${kpis.completedTrips}',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                if (kpis.cancelledTrips > 0)
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: kpis.cancelledTrips.toDouble(),
                                    title: '${kpis.cancelledTrips}',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                if (tripsOther > 0)
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value: tripsOther.toDouble(),
                                    title: '$tripsOther',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildLegendItem(Colors.green, 'مكتملة'),
                      _buildLegendItem(Colors.red, 'ملغاة'),
                      _buildLegendItem(Colors.orange, 'أخرى'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'الحجوزات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (kpis.periodBookings == 0)
                        const SizedBox(
                          height: 150,
                          child: Center(child: Text('لا بيانات')),
                        )
                      else
                        SizedBox(
                          height: 150,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: [
                                if (kpis.completedBookings > 0)
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: kpis.completedBookings.toDouble(),
                                    title: '${kpis.completedBookings}',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                if (kpis.cancelledBookings > 0)
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: kpis.cancelledBookings.toDouble(),
                                    title: '${kpis.cancelledBookings}',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                if (bookingsOther > 0)
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value: bookingsOther.toDouble(),
                                    title: '$bookingsOther',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildLegendItem(Colors.green, 'مكتملة'),
                      _buildLegendItem(Colors.red, 'ملغاة'),
                      _buildLegendItem(Colors.orange, 'أخرى'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRoutes(List<TopRoute> routes) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أشهر المسارات (للفترة المحددة)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (routes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'لا توجد مسارات خلال الفترة المحددة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: routes.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    title: Text(
                      '${route.origin} إلى ${route.destination}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    ),
                    trailing: Text(
                      '${route.tripCount} رحلة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
