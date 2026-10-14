import 'package:flutter/material.dart';

class BookingStatusMapper {
  static String getLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الطلب';
      case 'awaiting_payment':
      case 'pending_payment':
        return 'بانتظار الدفع';
      case 'payment_verification':
        return 'جاري التحقق من الدفع';
      case 'awaiting_driver_verification':
        return 'بانتظار تحقق السائق';
      case 'confirmed':
        return 'مؤكد';
      case 'accepted':
        return 'مقبول';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      case 'expired':
        return 'منتهي';
      case 'support_review':
        return 'مراجعة الدعم';
      case 'cancelled_by_passenger':
        return 'ملغي من الراكب';
      case 'cancelled_by_driver':
        return 'ملغي من السائق';
      case 'payment_not_received':
        return 'لم يتم الدفع';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case 'pending':
      case 'awaiting_payment':
      case 'pending_payment':
      case 'payment_verification':
      case 'awaiting_driver_verification':
      case 'support_review':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'expired':
      case 'cancelled_by_passenger':
      case 'cancelled_by_driver':
      case 'payment_not_received':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case 'pending':
      case 'awaiting_payment':
      case 'pending_payment':
      case 'payment_verification':
      case 'awaiting_driver_verification':
      case 'support_review':
        return Icons.hourglass_empty;
      case 'confirmed':
      case 'accepted':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
      case 'rejected':
      case 'expired':
      case 'cancelled_by_passenger':
      case 'cancelled_by_driver':
      case 'payment_not_received':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class TripStatusMapper {
  static String getLabel(String status) {
    switch (status) {
      case 'published':
        return 'منشورة';
      case 'scheduled':
        return 'مجدولة';
      case 'active':
        return 'نشطة';
      case 'running':
      case 'started':
        return 'جارية';
      case 'completed':
      case 'finished':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      case 'draft':
        return 'مسودة';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case 'published':
      case 'scheduled':
        return Colors.blue;
      case 'active':
      case 'running':
      case 'started':
        return Colors.orange;
      case 'completed':
      case 'finished':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
