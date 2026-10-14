import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../trips/domain/models/booking.dart';
import '../../../trips/presentation/utils/booking_status_ui.dart';

class PassengerUpcomingBookingCard extends StatelessWidget {
  final Booking booking;

  const PassengerUpcomingBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final depCity = booking.departureCity.isNotEmpty
        ? booking.departureCity
        : 'نقطة الانطلاق';
    final arrCity = booking.arrivalCity.isNotEmpty
        ? booking.arrivalCity
        : 'الوجهة';

    final formattedDate = DateFormat(
      'yyyy/MM/dd – hh:mm a',
    ).format(booking.travelDate);

    // Status mapping using unified BookingStatusUI
    final statusUI = BookingStatusUI.fromStatus(booking.status);
    final statusText = statusUI.label;
    final statusBg = statusUI.backgroundColor;
    final statusFg = statusUI.foregroundColor;

    final cardBg = isDark ? const Color(0xFF141F30) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF0B1F3A).withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Semantics(
        button: true,
        label: 'حجز قادم من $depCity إلى $arrCity، الحالة: $statusText',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/booking-details/${booking.id}');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFF0B1F3A).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Status badge & Booking number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusFg,
                          ),
                        ),
                      ),
                      if (booking.bookingNumber.isNotEmpty)
                        Text(
                          '#${booking.bookingNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Route Row: Origin -> Destination
                  Row(
                    children: [
                      const Icon(
                        Icons.trip_origin_rounded,
                        size: 16,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          depCity,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0B1F3A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFF0B1F3A),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          arrCity,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0B1F3A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Bottom Info Row: Date + Driver name if available
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (booking.driverName.isNotEmpty)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  booking.driverName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
