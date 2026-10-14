import 'package:flutter/material.dart';
import '../../../trips/domain/models/booking.dart';
import '../../../../core/utils/rtl_format.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';

class DriverBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMessage;
  final VoidCallback onViewDetails;
  final Function(String) onMarkAttendance;

  const DriverBookingCard({
    super.key,
    required this.booking,
    required this.onAccept,
    required this.onReject,
    required this.onMessage,
    required this.onViewDetails,
    required this.onMarkAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = booking.currency.isNotEmpty ? booking.currency : 'YER';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(
        horizontal: DriverTokens.spaceMd,
        vertical: DriverTokens.spaceSm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        side: BorderSide(
          color: booking.status == 'payment_verification'
              ? DriverTokens.accentGold
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: booking.status == 'payment_verification' ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(DriverTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: DriverTokens.primaryNavy.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: DriverTokens.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.name.isNotEmpty
                                ? booking.name
                                : 'حجز #${booking.id.length > 5 ? booking.id.substring(0, 5).toUpperCase() : booking.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : DriverTokens.primaryNavy,
                              fontFamily: 'Cairo',
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '#${booking.id.length > 6 ? booking.id.substring(0, 6).toUpperCase() : booking.id} • ${RtlFormat.formatDate(booking.bookingTime)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: DriverTokens.spaceMd),

              // Info Row
              Container(
                padding: const EdgeInsets.all(DriverTokens.spaceSm),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900
                      : DriverTokens.backgroundLight,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(
                      'عدد المقاعد',
                      '${booking.seatCount.toInt()}',
                    ),
                    _buildInfoColumn(
                      'المقاعد',
                      booking.seatNumbers.isNotEmpty
                          ? booking.seatNumbers.join(', ')
                          : (booking.seatNumber.isNotEmpty
                                ? booking.seatNumber
                                : '—'),
                    ),
                    if (booking.depositAmount > 0) ...[
                      _buildInfoColumn(
                        'تأكيد الحجز',
                        '${booking.depositAmount.toInt()} $currency',
                        textColor: DriverTokens.semanticSuccess,
                      ),
                      _buildInfoColumn(
                        'المتبقي',
                        '${booking.remainingAmount.toInt()} $currency',
                        textColor: DriverTokens.semanticWarning,
                      ),
                    ] else ...[
                      _buildInfoColumn(
                        'الإجمالي',
                        '${booking.price.toInt()} $currency',
                        textColor: DriverTokens.primaryNavy,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: DriverTokens.spaceMd),

              // Contextual Actions
              if (booking.status == 'pending_payment' ||
                  booking.status == 'awaiting_payment')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DriverTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: DriverTokens.semanticWarning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      DriverTokens.radiusSmall,
                    ),
                    border: Border.all(
                      color: DriverTokens.semanticWarning.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        color: DriverTokens.semanticWarning,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بانتظار إرسال الراكب إثبات الدفع لاستكمال الحجز.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: DriverTokens.semanticWarning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (booking.status == 'payment_verification' ||
                  booking.status == 'awaiting_driver_verification')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(
                      Icons.receipt_long,
                      color: DriverTokens.accentGold,
                    ),
                    label: const Text(
                      'مراجعة إثبات الدفع والتحقق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTokens.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                ),

              if (booking.status == 'confirmed' || booking.status == 'accepted')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      onPressed: onMessage,
                      label: const Text(
                        'مراسلة',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DriverTokens.primaryNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DriverTokens.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                    if (booking.attendanceStatus == 'none')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => onMarkAttendance('present'),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(
                              'حاضر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverTokens.semanticSuccess,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () => onMarkAttendance('late'),
                            child: const Text(
                              'متأخر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () => onMarkAttendance('no_show'),
                            child: const Text(
                              'لم يحضر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: DriverTokens.semanticError,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (booking.attendanceStatus == 'present')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DriverTokens.semanticSuccess.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            DriverTokens.radiusSmall,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: DriverTokens.semanticSuccess,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'تم التحضير',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: DriverTokens.semanticSuccess,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (booking.attendanceStatus == 'late')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DriverTokens.semanticWarning.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            DriverTokens.radiusSmall,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: DriverTokens.semanticWarning,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'متأخر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: DriverTokens.semanticWarning,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (booking.attendanceStatus == 'no_show')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DriverTokens.semanticError.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            DriverTokens.radiusSmall,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 16,
                              color: DriverTokens.semanticError,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'لم يحضر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: DriverTokens.semanticError,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
    );
  }

  Widget _buildInfoColumn(String title, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 13,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final info = DriverBookingStatusUi.info(booking.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 13, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(
              color: info.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
