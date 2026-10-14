import 'package:flutter/material.dart';

class TripStatusBadge extends StatelessWidget {
  final String status;

  const TripStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'مسودة';
        break;
      case 'published':
        color = Colors.blue;
        label = 'منشورة';
        break;
      case 'open_for_booking':
        color = Colors.green;
        label = 'متاحة للحجز';
        break;
      case 'almost_full':
        color = Colors.orange;
        label = 'شبه ممتلئة';
        break;
      case 'full':
        color = Colors.redAccent;
        label = 'ممتلئة';
        break;
      case 'running':
        color = Colors.deepPurple;
        label = 'جارية';
        break;
      case 'completed':
        color = Colors.teal;
        label = 'مكتملة';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'ملغاة';
        break;
      default:
        color = Colors.grey;
        label = 'غير معروف';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
