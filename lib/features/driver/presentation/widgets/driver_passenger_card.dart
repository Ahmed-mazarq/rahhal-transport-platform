import 'package:flutter/material.dart';
import '../../../trips/domain/models/booking.dart';

class DriverPassengerCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onMessage;

  const DriverPassengerCard({
    super.key,
    required this.booking,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Passenger Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.name.isNotEmpty ? booking.name : 'مسافر',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'مقعد ${booking.seatNumber}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAttendanceBadge(),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue, size: 20),
                  onPressed: onMessage,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBadge() {
    Color color;
    String label;
    switch (booking.attendanceStatus) {
      case 'present':
        color = Colors.green;
        label = 'حاضر';
        break;
      case 'absent':
      case 'no_show':
        color = Colors.red;
        label = 'غائب';
        break;
      case 'late':
        color = Colors.orange;
        label = 'متأخر';
        break;
      default:
        color = Colors.grey;
        label = 'لم يحدد';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontFamily: 'Cairo'),
      ),
    );
  }
}
