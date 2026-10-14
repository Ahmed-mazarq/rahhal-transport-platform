import 'package:flutter/material.dart';
import '../utils/rtl_format.dart';
import '../../features/trips/domain/models/trip.dart';

class BookingCard extends StatelessWidget {
  final String bookingNumber;
  final Trip trip;
  final String bookingStatus;
  final String paymentStatus;
  final int passengerCount;
  final VoidCallback onViewDetails;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.bookingNumber,
    required this.trip,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.passengerCount,
    required this.onViewDetails,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    switch (bookingStatus) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'مؤكد';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'ملغى';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'مكتمل';
        break;
      default:
        statusColor = Colors.grey;
        statusText = bookingStatus;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'رقم الحجز: $bookingNumber',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  RtlFormat.formatPrice(trip.price * passengerCount),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Provider info
                Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: Icon(
                        trip.isCompany ? Icons.business : Icons.person,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        trip.isCompany ? trip.name : trip.driverName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Trip Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 12,
                            color: Color(0xFFF5A623),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trip.departureCity,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            RtlFormat.formatTime(trip.departureTime),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Container(
                          height: 20,
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trip.arrivalCity,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            RtlFormat.formatTime(trip.arrivalTime),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Footer / Actions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$passengerCount مسافرين',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text(
                          'إلغاء الحجز',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1F3A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onViewDetails,
                        child: const Text(
                          'التفاصيل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
