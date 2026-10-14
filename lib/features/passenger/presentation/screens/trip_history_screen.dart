import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rahal/core/theme/app_theme.dart';
import '../providers/passenger_providers.dart';
import '../../../trips/presentation/utils/booking_status_ui.dart';
import '../../../trips/domain/models/booking.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final bookingsState = ref.watch(passengerBookingsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'سجل الرحلات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingsState.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, index) => Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل سجل الرحلات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(passengerBookingsProvider),
                style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
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
                        Icons.history_rounded,
                        size: 38,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد رحلات سابقة',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'سجل رحلاتك وحجوزاتك سيظهر هنا فور اكتمالها.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: accentGold,
            onRefresh: () async {
              ref.invalidate(passengerBookingsProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _TripHistoryCard(
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
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  final Booking booking;
  final bool isDark;
  final Color primaryNavy;
  final Color accentGold;

  const _TripHistoryCard({
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
  Widget build(BuildContext context) {
    final statusUI = BookingStatusUI.fromStatus(booking.status);
    final formattedDate = DateFormat(
      'd MMMM yyyy',
      'ar',
    ).format(booking.travelDate);

    final bookingCode = booking.id.length >= 8
        ? booking.id.substring(0, 8).toUpperCase()
        : booking.id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/booking-details/${booking.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date & Status Pill
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
                          formattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
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
                        color: statusUI.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusUI.icon,
                            size: 12,
                            color: statusUI.foregroundColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusUI.label,
                            style: TextStyle(
                              fontSize: 11,
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
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                  ),
                ),

                // Route: Departure -> Arrival
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
                          height: 18,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            booking.arrivalCity,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
                          _formatPrice(booking.price, booking.currency),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'حجز #$bookingCode',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom row: Driver & Seat count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (booking.driverName.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 15,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.driverName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.seatCount.toInt()} مقاعد',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
