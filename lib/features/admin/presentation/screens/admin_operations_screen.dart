import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/admin_operations_provider.dart';

class AdminOperationsScreen extends ConsumerWidget {
  const AdminOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(opsDashboardStatsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'مركز العمليات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => ref.invalidate(opsDashboardStatsProvider),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(opsDashboardStatsProvider),
          child: statsAsync.when(
            data: (stats) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ملخص العمليات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'آخر تحديث: ${DateFormat('HH:mm').format(DateTime.now())}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isDesktop
                          ? 1.5
                          : (isTablet ? 1.2 : 1.1),
                      children: [
                        _buildOpCard(
                          context,
                          'الرحلات الجارية',
                          stats['running_trips'] ?? 0,
                          Icons.map,
                          Colors.blue,
                          '/admin/operations/trips',
                        ),
                        _buildOpCard(
                          context,
                          'الحجوزات',
                          stats['pending_bookings'] ?? 0,
                          Icons.book_online,
                          Colors.teal,
                          '/admin/operations/bookings',
                        ),
                        _buildOpCard(
                          context,
                          'تذاكر الدعم',
                          stats['open_tickets'] ?? 0,
                          Icons.support_agent,
                          Colors.redAccent,
                          '/admin/operations/support',
                        ),
                        _buildOpCard(
                          context,
                          'المستندات',
                          stats['pending_docs'] ?? 0,
                          Icons.verified_user,
                          Colors.orange,
                          '/admin/operations/documents',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'تحتاج إجراء الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionRow(
                      context,
                      'مراجعة المستندات بانتظار الاعتماد',
                      stats['pending_docs'] ?? 0,
                      Icons.file_present,
                      Colors.orange,
                      '/admin/operations/documents',
                    ),
                    _buildActionRow(
                      context,
                      'حجوزات تتطلب تدخل',
                      stats['pending_bookings'] ?? 0,
                      Icons.warning_amber_rounded,
                      Colors.teal,
                      '/admin/operations/bookings',
                    ),
                    _buildActionRow(
                      context,
                      'البلاغات المفتوحة',
                      stats['open_reports'] ?? 0,
                      Icons.report_problem,
                      Colors.red,
                      '/admin/operations/reports',
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'عمليات سريعة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickAction(
                          context,
                          'إدارة الأسطول',
                          Icons.directions_car,
                          '/admin/operations/fleet',
                        ),
                        _buildQuickAction(
                          context,
                          'المراقبة الحية',
                          Icons.monitor_heart,
                          '/admin/operations/live-monitor',
                        ),
                        _buildQuickAction(
                          context,
                          'الإشعارات',
                          Icons.notifications_active,
                          '/admin/operations/notifications',
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // Padding for bottom nav
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'خطأ في تحميل الإحصائيات: $err',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    const Text(
                      '0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => context.go(route),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontFamily: 'Cairo')),
      onPressed: () => context.go(route),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
