import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_collections_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/admin_global_search_delegate.dart';
import '../../../../core/theme/admin_theme.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;

    final statsAsyncValue = ref.watch(adminDashboardStatsProvider);
    final authState = ref.watch(authProvider);

    String adminName = 'المدير العام';
    String adminRole = 'Super Admin';
    if (authState is Authenticated) {
      adminName = authState.user.fullName.isNotEmpty
          ? authState.user.fullName
          : adminName;
      adminRole = authState.user.role == 'super_admin'
          ? 'Super Admin'
          : authState.user.role.toUpperCase();
    }

    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: _buildAppBar(context, adminName, adminRole),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(
                  context,
                  adminName,
                  adminRole,
                  statsAsyncValue,
                ),
                const SizedBox(height: 32),

                Text(
                  'مؤشرات الأداء المباشرة',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildKPIsGrid(context, statsAsyncValue, isDesktop, isTablet),
                const SizedBox(height: 32),

                Text(
                  'إجراءات سريعة',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(context, isDesktop, isTablet),
                const SizedBox(height: 32),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildRecentActivity(context, ref),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildSystemAlerts(context, statsAsyncValue),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRecentActivity(context, ref),
                      const SizedBox(height: 24),
                      _buildSystemAlerts(context, statsAsyncValue),
                    ],
                  ),

                const SizedBox(height: 32),
                _buildLiveStatus(context, statsAsyncValue),

                const SizedBox(height: 48),
                _buildLogoutSection(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String adminName,
    String adminRole,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppBar(
      title: Text(
        'لوحة القيادة الإدارية',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: AdminTheme.textPrimary,
          fontSize: isMobile ? 16 : 20,
        ),
      ),
      backgroundColor: AdminTheme.topBar,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AdminTheme.border, height: 1.0),
      ),
      actions: [
        if (!isMobile)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AdminTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: AdminTheme.success, size: 10),
                SizedBox(width: 8),
                Text(
                  'متصل',
                  style: TextStyle(
                    color: AdminTheme.success,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          icon: const Icon(Icons.search, color: AdminTheme.textSecondary),
          onPressed: () {
            showSearch(context: context, delegate: AdminGlobalSearchDelegate());
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AdminTheme.textSecondary,
          ),
          onPressed: () {
            context.go('/admin/operations/notifications');
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              if (!isMobile) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      adminName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    Text(
                      adminRole,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
              const CircleAvatar(
                backgroundColor: AdminTheme.primary,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    String adminName,
    String adminRole,
    AsyncValue statsAsyncValue,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdminTheme.primary, Color(0xFF1E293B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بعودتك، $adminName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'آخر تسجيل دخول: اليوم، ${TimeOfDay.now().format(context)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTheme.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AdminTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statsAsyncValue.hasError
                            ? Icons.error_outline
                            : Icons.check_circle,
                        color: statsAsyncValue.hasError
                            ? AdminTheme.danger
                            : AdminTheme.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statsAsyncValue.hasError
                              ? 'يوجد خلل في مزامنة البيانات'
                              : (statsAsyncValue.isLoading
                                    ? 'جاري مزامنة البيانات...'
                                    : 'الأنظمة تعمل بكفاءة عالية'),
                          style: TextStyle(
                            color: statsAsyncValue.hasError
                                ? AdminTheme.danger
                                : AdminTheme.success,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width >= 600)
            const Icon(
              Icons.analytics_outlined,
              size: 100,
              color: Colors.white12,
            ),
        ],
      ),
    );
  }

  Widget _buildKPIsGrid(
    BuildContext context,
    AsyncValue statsAsyncValue,
    bool isDesktop,
    bool isTablet,
  ) {
    int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 3);

    return statsAsyncValue.when(
      data: (stats) => LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 24.0;
          final double itemWidth =
              (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
              crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'الركاب',
                  stats.totalPassengers,
                  Icons.people_outline,
                  AdminTheme.passengerColor,
                  route: '/admin/users/passengers',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'السائقين',
                  stats.totalDrivers,
                  Icons.drive_eta_outlined,
                  AdminTheme.driverColor,
                  route: '/admin/users/drivers',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'الشركات',
                  stats.totalCompanies,
                  Icons.business_outlined,
                  AdminTheme.companyColor,
                  route: '/admin/users/companies',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'المركبات',
                  stats.totalVehicles,
                  Icons.local_taxi_outlined,
                  AdminTheme.vehicleColor,
                  route: '/admin/operations/fleet',
                ),
              ),

              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'إجمالي الرحلات',
                  stats.totalTrips,
                  Icons.map_outlined,
                  AdminTheme.tripColor,
                  route: '/admin/operations/trips',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'الرحلات الجارية',
                  stats.activeTrips,
                  Icons.navigation_outlined,
                  AdminTheme.success,
                  route: '/admin/operations/trips',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'رحلات اليوم',
                  stats.todaysTrips,
                  Icons.today_outlined,
                  AdminTheme.secondary,
                  route: '/admin/operations/trips',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'الحجوزات',
                  stats.totalBookings,
                  Icons.book_online_outlined,
                  AdminTheme.bookingColor,
                  route: '/admin/operations/bookings',
                ),
              ),

              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'سائقين متاحين',
                  stats.onlineDrivers,
                  Icons.online_prediction_outlined,
                  AdminTheme.success,
                  route: '/admin/users/drivers',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'شركات نشطة',
                  stats.activeCompanies,
                  Icons.storefront_outlined,
                  AdminTheme.success,
                  route: '/admin/users/companies',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'التقييم العام',
                  stats.averageRating,
                  Icons.star_outline,
                  AdminTheme.warning,
                  suffix: ' ★',
                  fractionDigits: 1,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'النمو الشهري',
                  stats.platformGrowth,
                  Icons.trending_up,
                  AdminTheme.success,
                  prefix: '+',
                  suffix: '%',
                  fractionDigits: 1,
                ),
              ),

              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'مستندات معلقة',
                  stats.pendingDocuments,
                  Icons.pending_actions,
                  AdminTheme.danger,
                  route: '/admin/operations/documents',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'تذاكر الدعم',
                  stats.openTickets,
                  Icons.support_agent_outlined,
                  Colors.deepOrange,
                  route: '/admin/operations/support',
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildStatCard(
                  context,
                  'البلاغات',
                  stats.totalReports,
                  Icons.report_problem_outlined,
                  AdminTheme.danger,
                  route: '/admin/operations/support',
                ),
              ),
            ],
          );
        },
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => _buildRetryCard(err.toString()),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    num value,
    IconData icon,
    Color color, {
    String route = '',
    String prefix = '',
    String suffix = '',
    int fractionDigits = 0,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      color: AdminTheme.card,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: InkWell(
        onTap: route.isNotEmpty ? () => context.go(route) : null,
        borderRadius: BorderRadius.circular(18),
        hoverColor: color.withValues(alpha: 0.05),
        splashColor: color.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: isMobile ? 18 : 24),
                  ),
                  if (!isMobile) const SizedBox(width: 12),
                  if (!isMobile)
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (isMobile) const SizedBox(height: 8),
              if (isMobile)
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: isMobile ? 4 : 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value.toDouble()),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      '$prefix${val.toStringAsFixed(fractionDigits)}$suffix',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isMobile ? 18 : 26,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryCard(String error) {
    return Card(
      color: AdminTheme.danger.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AdminTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AdminTheme.danger),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'فشل تحميل البيانات الحية.\n$error',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AdminTheme.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    int count = isDesktop ? 6 : (isTablet ? 4 : 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 16.0;
        final double itemWidth =
            (constraints.maxWidth - (spacing * (count - 1))) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'طلبات اعتماد الحسابات',
                Icons.how_to_reg_outlined,
                Colors.deepOrange,
                '/admin/approvals',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'المستخدمين',
                Icons.people_outline,
                AdminTheme.secondary,
                '/admin/users',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'المستندات',
                Icons.description_outlined,
                Colors.indigo,
                '/admin/operations/documents',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'الرحلات',
                Icons.map_outlined,
                AdminTheme.success,
                '/admin/operations/trips',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'الحجوزات',
                Icons.book_online_outlined,
                Colors.teal,
                '/admin/operations/bookings',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'الدعم والبلاغات',
                Icons.support_agent_outlined,
                AdminTheme.warning,
                '/admin/operations/support',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'الإشعارات',
                Icons.notifications_outlined,
                Colors.purple,
                '/admin/operations/notifications',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'الصلاحيات',
                Icons.admin_panel_settings_outlined,
                AdminTheme.primary,
                '/admin/settings/roles',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                'المركز الأمني',
                Icons.security_outlined,
                AdminTheme.danger,
                '/admin/settings/security',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: AdminTheme.card,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: 0.05),
        splashColor: color.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isMobile ? 24 : 28),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isMobile ? 12 : 14,
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final activityStream = ref.watch(
      adminCollectionStreamProvider('audit_logs'),
    );

    return Card(
      elevation: 0,
      color: AdminTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أحدث النشاطات',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                Icon(Icons.history, color: AdminTheme.textMuted),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AdminTheme.border),
            activityStream.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'لا توجد نشاطات حديثة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }
                final recentLogs = logs.take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLogs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AdminTheme.border),
                  itemBuilder: (context, index) {
                    final log = recentLogs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.track_changes,
                          color: AdminTheme.secondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        log['action'] ?? 'إجراء غير محدد',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        log['description'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                      trailing: Text(
                        log['timestamp'] != null
                            ? log['timestamp'].toString().substring(11, 16)
                            : '',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text(
                'خطأ: $err',
                style: const TextStyle(color: AdminTheme.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemAlerts(BuildContext context, AsyncValue statsAsyncValue) {
    return Card(
      elevation: 0,
      color: AdminTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تنبيهات النظام',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                Icon(Icons.warning_amber_rounded, color: AdminTheme.warning),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AdminTheme.border),
            statsAsyncValue.when(
              data: (stats) {
                List<Widget> alerts = [];
                if (stats.pendingDocuments > 0) {
                  alerts.add(
                    _buildAlertTile(
                      'مستندات معلقة',
                      'يوجد ${stats.pendingDocuments} مستند ينتظر المراجعة.',
                      Icons.description_outlined,
                      AdminTheme.warning,
                    ),
                  );
                }
                if (stats.openTickets > 0) {
                  alerts.add(
                    _buildAlertTile(
                      'تذاكر دعم',
                      'يوجد ${stats.openTickets} تذكرة مفتوحة تحتاج لرد.',
                      Icons.support_outlined,
                      AdminTheme.danger,
                    ),
                  );
                }
                if (stats.totalReports > 0) {
                  alerts.add(
                    _buildAlertTile(
                      'بلاغات نشطة',
                      'تم تسجيل ${stats.totalReports} بلاغ جديد.',
                      Icons.report_outlined,
                      AdminTheme.danger,
                    ),
                  );
                }

                if (alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'لا توجد تنبيهات عاجلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AdminTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AdminTheme.border),
                  itemBuilder: (context, index) => alerts[index],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => const Text('غير متاح'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: AdminTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLiveStatus(BuildContext context, AsyncValue statsAsyncValue) {
    return Card(
      elevation: 0,
      color: AdminTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            const Icon(Icons.speed, color: AdminTheme.secondary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حالة النظام الحية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  statsAsyncValue.when(
                    data: (stats) => Text(
                      'الأنظمة مستقرة. أحدث مزامنة للبيانات كانت منذ ${stats.lastUpdated.difference(DateTime.now()).inSeconds.abs()} ثانية.',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    loading: () => const Text(
                      'جاري المزامنة...',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    error: (err, stack) => const Text(
                      'يوجد خلل في مزامنة بعض البيانات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AdminTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (MediaQuery.of(context).size.width >= 600)
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync),
                label: const Text(
                  'مزامنة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: Colors.red.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          onTap: () {
            ref.read(authProvider.notifier).logout().then((_) {
              if (context.mounted) {
                context.go('/admin-login');
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.red.withValues(alpha: 0.1),
          splashColor: Colors.red.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الخروج من بوابة إدارة رحال',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
