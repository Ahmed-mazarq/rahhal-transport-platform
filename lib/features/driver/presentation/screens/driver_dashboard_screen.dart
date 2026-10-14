import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/providers/repository_providers.dart';
import '../providers/driver_providers.dart';
import '../providers/driver_badges_provider.dart';
import '../providers/driver_navigation_provider.dart';
import '../providers/driver_activity_provider.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';
import '../../../trips/domain/models/trip.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _isTogglingOnline = false;

  Future<void> _toggleAvailability(
    bool val,
    String driverId,
    String driverStatus,
  ) async {
    if (_isTogglingOnline) return;

    if (driverStatus != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن تفعيل الحالة؛ حسابك بانتظار المراجعة والاعتماد من الإدارة.',
            textAlign: TextAlign.right,
          ),
          backgroundColor: DriverTokens.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isTogglingOnline = true);
    HapticFeedback.selectionClick();

    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.updateOnlineStatus(driverId, val);
      ref.invalidate(driverProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              val
                  ? 'أنت متصل الآن وجاهز لاستقبال طلبات الحجز'
                  : 'تم تغيير حالتك إلى غير متصل',
              textAlign: TextAlign.right,
            ),
            backgroundColor: val ? DriverTokens.success : Colors.grey[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ref.invalidate(driverProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحديث حالة الاتصال، يرجى التحقق من اتصالك والمحاولة مجدداً.',
              textAlign: TextAlign.right,
            ),
            backgroundColor: DriverTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(driverProfileProvider);
    final upcomingTripAsync = ref.watch(driverUpcomingTripProvider);
    final todaySummaryAsync = ref.watch(driverTodaySummaryProvider);
    final performanceAsync = ref.watch(driverPerformanceProvider);
    final activityAsync = ref.watch(driverActivityProvider);
    final actionRequiredCount =
        ref.watch(driverActionRequiredBookingsCountProvider).value ?? 0;
    final unreadNotifs =
        ref.watch(driverUnreadNotificationsCountProvider).value ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : DriverTokens.backgroundLight,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(driverProfileProvider);
              ref.invalidate(driverUpcomingTripProvider);
              ref.invalidate(driverTodaySummaryProvider);
              ref.invalidate(driverPerformanceProvider);
              ref.invalidate(driverActivityProvider);
              ref.invalidate(driverActionRequiredBookingsCountProvider);
              ref.invalidate(driverUnreadNotificationsCountProvider);
            },
            color: DriverTokens.primaryNavy,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Driver Premium Header
                  profileAsync.when(
                    data: (profile) => _buildHeader(
                      context,
                      isDark,
                      profile?.fullName ?? 'كابتن',
                      profile?.status ?? 'pending',
                      profile?.profileImage,
                      unreadNotifs,
                    ),
                    loading: () => _buildHeaderLoading(isDark),
                    error: (_, _) => _buildHeader(
                      context,
                      isDark,
                      'كابتن',
                      'pending',
                      null,
                      unreadNotifs,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Availability Card
                  profileAsync.maybeWhen(
                    data: (profile) => _buildAvailabilityCard(
                      isDark,
                      profile?.isOnline ?? false,
                      profile?.status ?? 'pending',
                      profile?.id ?? '',
                    ),
                    orElse: () =>
                        _buildAvailabilityCard(isDark, false, 'pending', ''),
                  ),
                  const SizedBox(height: 16),

                  // 3. Driver Action Center (Required Actions)
                  if (actionRequiredCount > 0) ...[
                    _buildActionRequiredCard(isDark, actionRequiredCount),
                    const SizedBox(height: 16),
                  ],

                  // 4. Next Trip Card
                  upcomingTripAsync.when(
                    data: (trip) => _buildNextTripCard(context, isDark, trip),
                    loading: () => _buildCardSkeleton(isDark, height: 140),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // 5. Quick Operations Grid
                  _buildSectionHeader('العمليات السريعة', isDark),
                  const SizedBox(height: 10),
                  _buildQuickOperationsGrid(context, isDark),
                  const SizedBox(height: 20),

                  // 6. Today Overview
                  _buildSectionHeader('ملخص اليوم', isDark),
                  const SizedBox(height: 10),
                  todaySummaryAsync.when(
                    data: (summary) => _buildTodaySummaryGrid(isDark, summary),
                    loading: () => _buildCardSkeleton(isDark, height: 100),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // 7. Performance Snippet
                  performanceAsync.maybeWhen(
                    data: (data) =>
                        _buildPerformanceBanner(context, isDark, data),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // 8. Recent Activity Feed
                  _buildSectionHeader(
                    'النشاط الأخير',
                    isDark,
                    onSeeAll: () => context.push('/driver-activity'),
                  ),
                  const SizedBox(height: 10),
                  activityAsync.when(
                    data: (items) =>
                        _buildRecentActivityList(context, isDark, items),
                    loading: () => _buildCardSkeleton(isDark, height: 120),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    String name,
    String status,
    String? photoUrl,
    int unreadCount,
  ) {
    final accountStatus = DriverAccountStatusUi.fromStatus(status);
    final firstName = name.trim().split(' ').first;

    return Row(
      children: [
        // Avatar
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(driverTabIndexProvider.notifier).state = 4;
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DriverTokens.accentGold, width: 2),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          _buildAvatarFallback(firstName),
                    )
                  : _buildAvatarFallback(firstName),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Welcome & Status Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، كابتن $firstName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : DriverTokens.primaryNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accountStatus.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    accountStatus.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: accountStatus.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notification Shortcut
        IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(driverTabIndexProvider.notifier).state = 3;
          },
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            backgroundColor: DriverTokens.error,
            child: Icon(
              Icons.notifications_outlined,
              size: 26,
              color: isDark ? Colors.white : DriverTokens.primaryNavy,
            ),
          ),
          tooltip: 'الإشعارات',
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: DriverTokens.primaryNavy,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0] : 'ك',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeaderLoading(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? DriverTokens.cardDark : Colors.white,
        borderRadius: DriverTokens.borderSmall,
      ),
    );
  }

  Widget _buildAvailabilityCard(
    bool isDark,
    bool isOnline,
    String status,
    String driverId,
  ) {
    final isApproved = status == 'approved';
    final cardColor = isOnline
        ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9))
        : (isDark ? DriverTokens.cardDark : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: DriverTokens.borderCard,
        border: Border.all(
          color: isOnline
              ? DriverTokens.success.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: DriverTokens.cardShadow(isDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOnline
                  ? DriverTokens.success.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline
                  ? Icons.wifi_tethering_rounded
                  : Icons.portable_wifi_off_rounded,
              color: isOnline ? DriverTokens.success : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApproved
                      ? (isOnline ? 'متصل — تستقبل الطلبات' : 'غير متصل')
                      : 'الحساب غير جاهز للعمل',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isOnline
                        ? DriverTokens.success
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isApproved
                      ? (isOnline
                            ? 'يمكن للركاب حجز المقاعد وإرسال الطرود'
                            : 'قم بتفعيل الاتصال عند رغبتك بالعمل')
                      : 'يلزم اعتماد وثائقك من الإدارة لتفعيل الاتصال',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (_isTogglingOnline)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: isApproved && isOnline,
              activeThumbColor: DriverTokens.success,
              onChanged: isApproved
                  ? (val) => _toggleAvailability(val, driverId, status)
                  : (_) => _toggleAvailability(true, driverId, status),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRequiredCard(bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF33200B) : const Color(0xFFFFF8E1),
        borderRadius: DriverTokens.borderCard,
        border: Border.all(color: DriverTokens.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DriverTokens.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: DriverTokens.warning,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يتطلب إجراء ($count)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DriverTokens.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'لديك طلبات حجز أو إشعارات سداد بانتظار مراجعتك وتأكيدك.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(driverTabIndexProvider.notifier).state =
                  2; // Bookings tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTokens.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'مراجعة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextTripCard(BuildContext context, bool isDark, Trip? trip) {
    if (trip == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? DriverTokens.cardDark : Colors.white,
          borderRadius: DriverTokens.borderCard,
          border: Border.all(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  color: Colors.grey[400],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'لا توجد رحلة قادمة حالياً',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/create-trip'),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('إنشاء رحلة'),
            ),
          ],
        ),
      );
    }

    final formattedDate = DateFormat(
      'yyyy/MM/dd - hh:mm a',
      'ar',
    ).format(trip.departureTime);
    final statusUi = DriverTripStatusUi.fromStatus(trip.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DriverTokens.cardDark : Colors.white,
        borderRadius: DriverTokens.borderCard,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: DriverTokens.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.near_me_rounded,
                    color: DriverTokens.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'رحلتك القادمة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : DriverTokens.primaryNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusUi.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusUi.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusUi.foregroundColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${trip.departureCity} ➔ ${trip.arrivalCity}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Icon(Icons.event_seat_rounded, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'المقاعد: ${(trip.totalSeats - trip.remainingSeats).clamp(0, trip.totalSeats)}/${trip.totalSeats}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '/driver-trip-details/${trip.id}',
                    extra: trip,
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('عرض التفاصيل'),
                ),
              ),
              if (trip.status == 'running') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/driver-live-trip', extra: trip),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('متابعة الرحلة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTokens.accentGold,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOperationsGrid(BuildContext context, bool isDark) {
    final actions = [
      {
        'title': 'إنشاء رحلة',
        'icon': Icons.add_road_rounded,
        'color': DriverTokens.primaryNavy,
        'route': '/create-trip',
      },
      {
        'title': 'مركباتي',
        'icon': Icons.directions_car_rounded,
        'color': DriverTokens.info,
        'route': '/driver-vehicles',
      },
      {
        'title': 'طرق الدفع',
        'icon': Icons.account_balance_wallet_rounded,
        'color': DriverTokens.success,
        'route': '/payment-methods',
      },
      {
        'title': 'سوق الطرود',
        'icon': Icons.inventory_2_rounded,
        'color': DriverTokens.warning,
        'route': '/driver-parcels',
      },
      {
        'title': 'المستندات',
        'icon': Icons.badge_rounded,
        'color': const Color(0xFF7B1FA2),
        'route': '/driver-documents',
      },
      {
        'title': 'الدعم الفني',
        'icon': Icons.support_agent_rounded,
        'color': const Color(0xFF00796B),
        'route': '/driver-support',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final a = actions[index];
        final color = a['color'] as Color;

        return InkWell(
          borderRadius: DriverTokens.borderSmall,
          onTap: () => context.push(a['route'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? DriverTokens.cardDark : Colors.white,
              borderRadius: DriverTokens.borderSmall,
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: DriverTokens.cardShadow(isDark),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  a['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySummaryGrid(bool isDark, Map<String, int> summary) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            isDark,
            title: 'رحلات اليوم',
            value: '${summary['todayTrips'] ?? 0}',
            icon: Icons.calendar_today_rounded,
            color: DriverTokens.primaryNavy,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            isDark,
            title: 'بانتظار المراجعة',
            value: '${summary['pendingReviews'] ?? 0}',
            icon: Icons.hourglass_top_rounded,
            color: DriverTokens.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            isDark,
            title: 'ركاب مؤكدون',
            value: '${summary['confirmedPassengers'] ?? 0}',
            icon: Icons.people_alt_rounded,
            color: DriverTokens.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DriverTokens.cardDark : Colors.white,
        borderRadius: DriverTokens.borderSmall,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : DriverTokens.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBanner(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> data,
  ) {
    final double completionRate = data['completionRate'] ?? 1.0;
    final int completedTrips = data['completedTrips'] ?? 0;
    final double? rating = data['avgRating'];

    return InkWell(
      borderRadius: DriverTokens.borderCard,
      onTap: () => context.push('/driver-stats'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? DriverTokens.cardDark : Colors.white,
          borderRadius: DriverTokens.borderCard,
          border: Border.all(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: DriverTokens.cardShadow(isDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DriverTokens.accentGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: DriverTokens.accentGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مؤشرات الأداء والإحصائيات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'التقييم: ${rating != null ? rating.toStringAsFixed(1) : "جديد"} • الإكمال: ${(completionRate * 100).toInt()}% • $completedTrips رحلة',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(
    BuildContext context,
    bool isDark,
    List<DriverActivityItem> items,
  ) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? DriverTokens.cardDark : Colors.white,
          borderRadius: DriverTokens.borderSmall,
        ),
        child: const Center(
          child: Text(
            'لا يوجد نشاط مسجل مؤخراً',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    final topItems = items.take(4).toList();

    return Column(
      children: topItems.map((item) {
        final timeStr = DateFormat(
          'MM/dd hh:mm a',
          'ar',
        ).format(item.timestamp);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: DriverTokens.borderSmall,
            side: BorderSide(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          color: isDark ? DriverTokens.cardDark : Colors.white,
          child: ListTile(
            dense: true,
            onTap: item.route != null ? () => context.push(item.route!) : null,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              timeStr,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            trailing: item.route != null
                ? const Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: Colors.grey,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool isDark, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : DriverTokens.primaryNavy,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('عرض الكل', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildCardSkeleton(bool isDark, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? DriverTokens.cardDark : Colors.white,
        borderRadius: DriverTokens.borderCard,
      ),
    );
  }
}
