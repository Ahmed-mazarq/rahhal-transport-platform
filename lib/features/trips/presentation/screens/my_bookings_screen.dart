import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rahal/core/providers/repository_providers.dart';
import 'package:rahal/core/theme/app_theme.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/presentation/utils/booking_status_ui.dart';
import 'package:rahal/features/dashboard/presentation/providers/passenger_navigation_provider.dart';
import 'package:rahal/core/widgets/rahhal_app_bar.dart';

final passengerAllBookingsProvider = StreamProvider.autoDispose<List<Booking>>((
  ref,
) {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) return Stream.value([]);
  final user = authState.user;

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('passengerId', isEqualTo: user.id)
      .snapshots()
      .map((snapshot) {
        final bookings = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Booking.fromJson(data);
        }).toList();

        bookings.sort((a, b) {
          final aDate = a.createdAt ?? a.bookingTime;
          final bDate = b.createdAt ?? b.bookingTime;
          return bDate.compareTo(aDate);
        });

        return bookings;
      });
});

final tripCurrencyCachedProvider = FutureProvider.family<String, String>((
  ref,
  tripId,
) async {
  if (tripId.isEmpty) return '';
  final repo = ref.watch(tripRepositoryProvider);
  final trip = await repo.getTrip(tripId);
  return trip?.currency ?? '';
});

enum BookingFilterTab {
  all, // الكل
  actionRequired, // يحتاج إجراء
  underReview, // قيد المراجعة
  upcoming, // قادمة
  completed, // مكتملة
  cancelled, // ملغية
}

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  BookingFilterTab _selectedTab = BookingFilterTab.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final bookingsAsync = ref.watch(passengerAllBookingsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: RahhalAppBar(
        titleText: 'حجوزاتي',
        onBackPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            ref.read(passengerTabIndexProvider.notifier).state = 0;
          }
        },
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          bookingsAsync.maybeWhen(
            data: (bookings) =>
                _buildFilterChips(bookings, isDark, primaryNavy, accentGold),
            orElse: () =>
                _buildFilterChips([], isDark, primaryNavy, accentGold),
          ),

          // Bookings List
          Expanded(
            child: bookingsAsync.when(
              loading: () => _buildLoadingSkeleton(isDark),
              error: (err, _) => _buildErrorState(ref, isDark, primaryNavy),
              data: (allBookings) {
                final filtered = _filterBookings(allBookings, _selectedTab);
                if (filtered.isEmpty) {
                  return _buildEmptyState(_selectedTab, isDark, primaryNavy);
                }

                return RefreshIndicator(
                  color: accentGold,
                  onRefresh: () async {
                    ref.invalidate(passengerAllBookingsProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final booking = filtered[index];
                      return _BookingCard(
                        booking: booking,
                        isDark: isDark,
                        primaryNavy: primaryNavy,
                        accentGold: accentGold,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    List<Booking> allBookings,
    bool isDark,
    Color primaryNavy,
    Color accentGold,
  ) {
    int getCount(BookingFilterTab tab) {
      if (allBookings.isEmpty) return 0;
      return _filterBookings(allBookings, tab).length;
    }

    final tabs = [
      (BookingFilterTab.all, 'الكل'),
      (BookingFilterTab.actionRequired, 'يحتاج إجراء'),
      (BookingFilterTab.underReview, 'قيد المراجعة'),
      (BookingFilterTab.upcoming, 'قادمة'),
      (BookingFilterTab.completed, 'مكتملة'),
      (BookingFilterTab.cancelled, 'ملغية'),
    ];

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: tabs.map((t) {
            final tab = t.$1;
            final label = t.$2;
            final isSelected = _selectedTab == tab;
            final count = getCount(tab);

            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTab = tab);
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
                      if (allBookings.isNotEmpty && count > 0) ...[
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

  List<Booking> _filterBookings(List<Booking> bookings, BookingFilterTab tab) {
    if (tab == BookingFilterTab.all) return bookings;
    return bookings.where((b) {
      final ui = BookingStatusUI.fromStatus(b.status);
      switch (tab) {
        case BookingFilterTab.actionRequired:
          return ui.category == BookingStatusCategory.actionRequired;
        case BookingFilterTab.underReview:
          return ui.category == BookingStatusCategory.underReview;
        case BookingFilterTab.upcoming:
          return ui.category == BookingStatusCategory.upcoming;
        case BookingFilterTab.completed:
          return ui.category == BookingStatusCategory.completed;
        case BookingFilterTab.cancelled:
          return ui.category == BookingStatusCategory.cancelled;
        case BookingFilterTab.all:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState(
    BookingFilterTab tab,
    bool isDark,
    Color primaryNavy,
  ) {
    String title;
    String subtitle;
    IconData icon;

    switch (tab) {
      case BookingFilterTab.actionRequired:
        title = 'لا توجد حجوزات تتطلب إجراء';
        subtitle = 'جميع حجوزاتك الحالية مؤكدة أو قيد المراجعة.';
        icon = Icons.check_circle_outline_rounded;
        break;
      case BookingFilterTab.underReview:
        title = 'لا توجد حجوزات قيد المراجعة';
        subtitle = 'لا توجد طلبات حجز بانتظار موافقة السائق أو التحقق حالياً.';
        icon = Icons.hourglass_empty_rounded;
        break;
      case BookingFilterTab.upcoming:
        title = 'لا توجد رحلات قادمة';
        subtitle = 'احجز رحلتك القادمة بكل سهولة من خلال البحث عن رحلات متاحة.';
        icon = Icons.luggage_outlined;
        break;
      case BookingFilterTab.completed:
        title = 'لا توجد رحلات مكتملة بعد';
        subtitle = 'سجل رحلاتك السابقة المكتملة سيظهر هنا.';
        icon = Icons.history_rounded;
        break;
      case BookingFilterTab.cancelled:
        title = 'لا توجد حجوزات ملغية';
        subtitle = 'لم يتم إلغاء أي من حجوزاتك.';
        icon = Icons.cancel_outlined;
        break;
      case BookingFilterTab.all:
        title = 'لا توجد حجوزات حالياً';
        subtitle = 'لم تقم بإجراء أي حجوزات بعد. ابدأ رحلتك الآن!';
        icon = Icons.confirmation_number_outlined;
        break;
    }

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
              child: Icon(icon, size: 38, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (tab == BookingFilterTab.all ||
                tab == BookingFilterTab.upcoming) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(passengerTabIndexProvider.notifier).state = 1;
                },
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('ابحث عن رحلة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل حجوزاتك',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تحقق من الاتصال بالإنترنت ثم أعد المحاولة.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.invalidate(passengerAllBookingsProvider),
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

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final bool isDark;
  final Color primaryNavy;
  final Color accentGold;

  const _BookingCard({
    required this.booking,
    required this.isDark,
    required this.primaryNavy,
    required this.accentGold,
  });

  String _formatPrice(double price, String currency) {
    final formatted = price % 1 == 0
        ? price.toInt().toString()
        : price.toStringAsFixed(1);
    final upper = currency.toUpperCase().trim();
    if (upper == 'YER' || upper == 'YER_RIYAL') {
      return '$formatted ر.ي';
    } else if (upper == 'SAR' || upper == 'SAR_RIYAL') {
      return '$formatted ر.س';
    } else if (upper.isNotEmpty) {
      return '$formatted $currency';
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusUI = BookingStatusUI.fromStatus(booking.status);

    // Currency Resolution: If booking.currency is empty, resolve via cached trip provider
    final resolvedCurrency = booking.currency.isNotEmpty
        ? booking.currency
        : ref
              .watch(tripCurrencyCachedProvider(booking.tripId))
              .maybeWhen(data: (c) => c, orElse: () => '');

    // Payment deadline check for pending_payment
    final isActionablePayment =
        booking.status == 'pending_payment' ||
        booking.status == 'awaiting_payment';
    final hasDeadline = booking.paymentDeadline != null;
    final isDeadlineExpired =
        hasDeadline && booking.paymentDeadline!.isBefore(DateTime.now());

    final bookingCode = booking.id.length >= 8
        ? booking.id.substring(0, 8).toUpperCase()
        : booking.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/booking-details/${booking.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Booking Number + Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.confirmation_number_rounded,
                          size: 16,
                          color: primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'حجز #$bookingCode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusUI.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusUI.icon,
                            size: 14,
                            color: statusUI.foregroundColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusUI.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusUI.foregroundColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ),

                // Route (Departure -> Arrival)
                Row(
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.trip_origin_rounded,
                          color: Colors.green,
                          size: 14,
                        ),
                        Container(
                          height: 20,
                          width: 2,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        Icon(
                          Icons.location_on_rounded,
                          color: accentGold,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.departureCity,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            booking.arrivalCity,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(booking.price, resolvedCurrency),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.seatCount.toInt()} ${booking.seatCount == 1 ? "مقعد" : "مقاعد"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Travel Date & Seats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'السفر: ${DateFormat('yyyy/MM/dd', 'ar').format(booking.travelDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    if (booking.seatNumbers.isNotEmpty ||
                        booking.seatNumber.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.event_seat_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'المقعد: ${booking.seatNumbers.isNotEmpty ? booking.seatNumbers.join(", ") : booking.seatNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Payment Deadline Alert
                if (isActionablePayment && hasDeadline) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDeadlineExpired
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDeadlineExpired
                              ? Icons.error_outline_rounded
                              : Icons.access_time_rounded,
                          size: 14,
                          color: isDeadlineExpired
                              ? Colors.red
                              : Colors.orange[800],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isDeadlineExpired
                                ? 'انتهت مهلة الدفع'
                                : 'أكمل الدفع قبل ${DateFormat('hh:mm a', 'ar').format(booking.paymentDeadline!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDeadlineExpired
                                  ? Colors.red
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Contextual CTA Row
                _buildContextualCTA(context, booking.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextualCTA(BuildContext context, String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'pending_payment':
      case 'awaiting_payment':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/booking-payment/${booking.id}'),
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: const Text('إكمال الدفع وإرفاق الإشعار'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case 'payment_verification':
      case 'awaiting_driver_verification':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/booking-details/${booking.id}'),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('عرض حالة التحقق'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  side: BorderSide(color: primaryNavy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        );

      case 'confirmed':
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/booking-details/${booking.id}'),
                icon: const Icon(Icons.directions_bus_rounded, size: 16),
                label: const Text('عرض تفاصيل الرحلة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        );

      case 'payment_not_received':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/booking-details/${booking.id}'),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('مراجعة العملية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/support'),
                icon: const Icon(Icons.support_agent_rounded, size: 16),
                label: const Text('الدعم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/booking-details/${booking.id}'),
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('التفاصيل'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  side: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: booking.isRated
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.rating != null
                                ? '${booking.rating!.toStringAsFixed(1)} تم التقييم'
                                : 'تم التقييم',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/rate-trip/${booking.tripId}',
                        extra: {
                          'bookingId': booking.id,
                          'driverId': booking.driverId,
                        },
                      ),
                      icon: const Icon(Icons.star_rate_rounded, size: 16),
                      label: const Text('قيّم الرحلة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
            ),
          ],
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/booking-details/${booking.id}'),
            icon: const Icon(Icons.info_outline_rounded, size: 16),
            label: const Text('عرض التفاصيل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryNavy,
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        );
    }
  }
}
