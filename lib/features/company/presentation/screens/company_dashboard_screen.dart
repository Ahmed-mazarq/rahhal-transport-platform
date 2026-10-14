import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/company_providers.dart';
// We'll assume a way to fetch recent bookings later

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF8F9FC),
        body: SafeArea(
          child: companyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B1F3A)),
            ),
            error: (err, stack) => Center(
              child: Text('حدث خطأ', style: TextStyle(fontFamily: 'Cairo')),
            ),
            data: (company) {
              if (company == null) {
                return const Center(
                  child: Text(
                    'لا توجد بيانات',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(companyProfileProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(company, isDark),
                    const SizedBox(height: 24),
                    _buildStatusAlerts(company),
                    const SizedBox(height: 24),
                    const Text(
                      'نظرة عامة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatsGrid(company),
                    const SizedBox(height: 24),
                    const Text(
                      'إجراءات سريعة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    const Text(
                      'الجدول الزمني والمهام (Smart Dashboard)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSmartDashboard(),
                    const SizedBox(height: 24),
                    const Text(
                      'أحدث الحجوزات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentBookings(context),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic company, bool isDark) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            image: company.logo.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(company.logo),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: company.logo.isEmpty
              ? const Icon(Icons.business, size: 30, color: Color(0xFF0B1F3A))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      company.name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (company.verificationStatus == 'verified')
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.verified, color: Colors.blue, size: 20),
                    ),
                ],
              ),
              Text(
                'مرحباً بعودتك، ${company.managerName.isNotEmpty ? company.managerName : "مدير النظام"}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusAlerts(dynamic company) {
    if (company.status == 'Approved') return const SizedBox.shrink();

    Color bgColor = Colors.orange.withValues(alpha: 0.1);
    Color fgColor = Colors.orange;
    String message = 'حساب الشركة قيد المراجعة والتدقيق.';

    if (company.status == 'Suspended' || company.status == 'Blocked') {
      bgColor = Colors.red.withValues(alpha: 0.1);
      fgColor = Colors.red;
      message =
          'تم إيقاف حساب الشركة. يرجى مراجعة الدعم الفني وتحديث الوثائق المطلوبة.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: fgColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic company) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'السائقين',
          '${company.driversCount}',
          Icons.person,
          Colors.blue,
        ),
        _buildStatCard(
          'المركبات',
          '${company.vehiclesCount}',
          Icons.directions_car,
          Colors.purple,
        ),
        _buildStatCard('رحلات اليوم', '5', Icons.route, Colors.green),
        _buildStatCard('حجوزات جديدة', '12', Icons.book_online, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionItem(
            context,
            'رحلة جديدة',
            Icons.add_circle,
            Colors.green,
            () => context.push('/create-trip'),
          ),
          _buildActionItem(
            context,
            'الموظفين',
            Icons.badge,
            Colors.blue,
            () => context.push('/company-employees'),
          ),
          _buildActionItem(
            context,
            'الفروع',
            Icons.store,
            Colors.orange,
            () => context.push('/company-branches'),
          ),
          _buildActionItem(
            context,
            'الإحصائيات',
            Icons.bar_chart,
            Colors.purple,
            () => context.push('/company-stats'),
          ),
          _buildActionItem(
            context,
            'الوثائق',
            Icons.folder_shared,
            Colors.teal,
            () => context.push('/company-documents'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartDashboard() {
    return Column(
      children: [
        _buildSmartAlert(
          'تنبيه صيانة',
          'المركبة (ABC-123) تقترب من موعد تغيير الزيت.',
          Icons.build,
          Colors.orange,
        ),
        _buildSmartAlert(
          'تحديث وثائق',
          'رخصة القيادة الخاصة بالسائق (محمد أحمد) تنتهي بعد 5 أيام.',
          Icons.warning,
          Colors.red,
        ),
        _buildSmartAlert(
          'رسالة نظام',
          'تم إضافة ميزة تقارير الأرباح الجديدة.',
          Icons.info,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSmartAlert(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRecentBookings(BuildContext context) {
    // Mock for now, until we tie in real bookings.
    return Column(
      children: [
        _buildBookingItem(
          'محمد عبدالسلام',
          'صنعاء - عدن',
          'قيد الانتظار',
          Colors.orange,
        ),
        _buildBookingItem('سالم علي', 'عدن - المكلا', 'مؤكد', Colors.green),
      ],
    );
  }

  Widget _buildBookingItem(
    String name,
    String trip,
    String status,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'الرحلة: $trip',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
