import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/notification_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/notification.dart' as model;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../utils/role_aware_notification_navigator.dart';
import 'package:rahal/features/dashboard/presentation/providers/passenger_navigation_provider.dart';
import 'package:rahal/features/driver/presentation/providers/driver_navigation_provider.dart';
import 'package:rahal/core/widgets/rahhal_app_bar.dart';

enum NotificationFilterTab {
  all, // الكل
  tripsAndBookings, // الرحلات والحجوزات (booking, trip)
  payments, // المدفوعات (payment)
  support, // الدعم (support)
  parcels, // الطرود (parcel)
  promotionsAndSystem, // العروض والنظام (promotion, system, general)
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilterTab _selectedFilter = NotificationFilterTab.all;

  void _markAllAsRead() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    HapticFeedback.selectionClick();
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead(authState.user.uid);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد الكل كمقروء'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: RahhalAppBar(
        titleText: 'الإشعارات',
        onBackPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            final authState = ref.read(authProvider);
            final role = authState is Authenticated
                ? authState.user.role
                : 'passenger';
            if (role == 'driver') {
              ref.read(driverTabIndexProvider.notifier).state = 0;
            } else {
              ref.read(passengerTabIndexProvider.notifier).state = 0;
            }
          }
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          notificationsAsync.maybeWhen(
            data: (list) =>
                _buildFilterChips(list, isDark, primaryNavy, accentGold),
            orElse: () =>
                _buildFilterChips([], isDark, primaryNavy, accentGold),
          ),

          // List
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                final filtered = _filterNotifications(
                  notifications,
                  _selectedFilter,
                );

                if (filtered.isEmpty) {
                  return _buildEmptyState(_selectedFilter, isDark);
                }

                return RefreshIndicator(
                  color: accentGold,
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          ref
                              .read(notificationRepositoryProvider)
                              .deleteNotification(notification.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حذف الإشعار'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: NotificationCard(
                          title: notification.title,
                          message: notification.body,
                          type: notification.category,
                          timestamp: notification.createdAt,
                          isRead: notification.isRead,
                          onTap: () {
                            if (!notification.isRead) {
                              ref
                                  .read(notificationRepositoryProvider)
                                  .markAsRead(notification.id);
                            }
                            final authState = ref.read(authProvider);
                            final role = authState is Authenticated
                                ? authState.user.role
                                : 'passenger';
                            // Safe allowlisted role-aware navigation
                            RoleAwareNotificationNavigator.navigate(
                              context,
                              notification.payload,
                              role: role,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => _buildLoadingSkeleton(isDark),
              error: (err, stack) => _buildErrorState(ref, isDark, primaryNavy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    List<model.Notification> allNotifications,
    bool isDark,
    Color primaryNavy,
    Color accentGold,
  ) {
    int getCount(NotificationFilterTab filter) {
      if (allNotifications.isEmpty) return 0;
      return _filterNotifications(allNotifications, filter).length;
    }

    final filters = [
      (NotificationFilterTab.all, 'الكل'),
      (NotificationFilterTab.tripsAndBookings, 'الرحلات والحجوزات'),
      (NotificationFilterTab.payments, 'المدفوعات'),
      (NotificationFilterTab.support, 'الدعم'),
      (NotificationFilterTab.parcels, 'الطرود'),
      (NotificationFilterTab.promotionsAndSystem, 'العروض والنظام'),
    ];

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            final filter = f.$1;
            final label = f.$2;
            final isSelected = _selectedFilter == filter;
            final count = getCount(filter);

            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = filter);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryNavy
                        : (isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF0F2F5)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? primaryNavy
                          : (isDark ? Colors.grey[800]! : Colors.transparent),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                      if (allNotifications.isNotEmpty && count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentGold
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.black87
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<model.Notification> _filterNotifications(
    List<model.Notification> list,
    NotificationFilterTab filter,
  ) {
    if (filter == NotificationFilterTab.all) return list;

    return list.where((n) {
      final cat = n.category.toLowerCase();
      switch (filter) {
        case NotificationFilterTab.tripsAndBookings:
          return cat == 'booking' || cat == 'trip';
        case NotificationFilterTab.payments:
          return cat == 'payment';
        case NotificationFilterTab.support:
          return cat == 'support';
        case NotificationFilterTab.parcels:
          return cat == 'parcel';
        case NotificationFilterTab.promotionsAndSystem:
          return cat == 'promotion' || cat == 'system' || cat == 'general';
        case NotificationFilterTab.all:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState(NotificationFilterTab filter, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252525)
                    : const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشعارات جديدة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'سنوافيك بآخر التحديثات والإشعارات فور توفرها.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 76,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, bool isDark, Color primaryNavy) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل الإشعارات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تحقق من الاتصال ثم أعد المحاولة.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => ref.invalidate(notificationsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
