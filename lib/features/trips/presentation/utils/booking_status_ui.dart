import 'package:flutter/material.dart';

enum BookingStatusCategory {
  actionRequired,
  underReview,
  upcoming,
  completed,
  cancelled,
}

class BookingStatusUI {
  final String label;
  final IconData icon;
  final BookingStatusCategory category;
  final Color backgroundColor;
  final Color foregroundColor;
  final String description;

  const BookingStatusUI({
    required this.label,
    required this.icon,
    required this.category,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.description,
  });

  Color get color => foregroundColor;

  /// Map any raw status (current or legacy) to a human-friendly Arabic presentation
  static BookingStatusUI fromStatus(String status) {
    switch (status) {
      // ACTION REQUIRED
      case 'pending_payment':
      case 'awaiting_payment':
        return const BookingStatusUI(
          label: 'بانتظار الدفع',
          icon: Icons.payment_rounded,
          category: BookingStatusCategory.actionRequired,
          backgroundColor: Color(0xFFFFF8E1),
          foregroundColor: Color(0xFFF57F17),
          description: 'يرجى إكمال تحويل العربون لتأكيد حجزك',
        );

      // UNDER REVIEW
      case 'payment_verification':
      case 'awaiting_driver_verification':
        return const BookingStatusUI(
          label: 'قيد التحقق',
          icon: Icons.hourglass_top_rounded,
          category: BookingStatusCategory.underReview,
          backgroundColor: Color(0xFFE3F2FD),
          foregroundColor: Color(0xFF1565C0),
          description: 'جاري مراجعة إشعار السداد من قِبل السائق',
        );
      case 'pending':
        return const BookingStatusUI(
          label: 'قيد الانتظار',
          icon: Icons.access_time_rounded,
          category: BookingStatusCategory.underReview,
          backgroundColor: Color(0xFFF3E5F5),
          foregroundColor: Color(0xFF7B1FA2),
          description: 'بانتظار موافقة السائق على الحجز',
        );
      case 'support_review':
        return const BookingStatusUI(
          label: 'مراجعة الدعم',
          icon: Icons.support_agent_rounded,
          category: BookingStatusCategory.underReview,
          backgroundColor: Color(0xFFECEFF1),
          foregroundColor: Color(0xFF455A64),
          description: 'تتم مراجعة الطلب بواسطة فريق الدعم',
        );

      // UPCOMING
      case 'confirmed':
      case 'accepted':
        return const BookingStatusUI(
          label: 'مؤكد',
          icon: Icons.check_circle_rounded,
          category: BookingStatusCategory.upcoming,
          backgroundColor: Color(0xFFE8F5E9),
          foregroundColor: Color(0xFF2E7D32),
          description: 'تم تأكيد حجزك وجاهز للانطلاق',
        );

      // COMPLETED
      case 'completed':
        return const BookingStatusUI(
          label: 'مكتملة',
          icon: Icons.task_alt_rounded,
          category: BookingStatusCategory.completed,
          backgroundColor: Color(0xFFE0F2F1),
          foregroundColor: Color(0xFF00695C),
          description: 'اكتملت الرحلة بنجاح',
        );

      // CANCELLED / EXPIRED / REJECTED
      case 'payment_not_received':
        return const BookingStatusUI(
          label: 'لم يُستلم الدفع',
          icon: Icons.error_outline_rounded,
          category: BookingStatusCategory.cancelled,
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFC62828),
          description: 'تعذر التحقق من الدفع، يرجى التواصل مع الدعم',
        );
      case 'expired':
        return const BookingStatusUI(
          label: 'انتهت المهلة',
          icon: Icons.timer_off_rounded,
          category: BookingStatusCategory.cancelled,
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFC62828),
          description: 'انتهت مهلة سداد العربون المحددة',
        );
      case 'cancelled_by_passenger':
        return const BookingStatusUI(
          label: 'ملغي بواسطتك',
          icon: Icons.cancel_outlined,
          category: BookingStatusCategory.cancelled,
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFC62828),
          description: 'تم إلغاء الحجز من جانبك',
        );
      case 'cancelled_by_driver':
        return const BookingStatusUI(
          label: 'ملغي من السائق',
          icon: Icons.cancel_outlined,
          category: BookingStatusCategory.cancelled,
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFC62828),
          description: 'تم إلغاء الحجز من قِبل السائق',
        );
      case 'cancelled':
        return const BookingStatusUI(
          label: 'ملغي',
          icon: Icons.cancel_outlined,
          category: BookingStatusCategory.cancelled,
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFC62828),
          description: 'تم إلغاء الحجز',
        );
      case 'rejected':
        return const BookingStatusUI(
          label: 'مرفوض',
          icon: Icons.block_rounded,
          category: BookingStatusCategory.cancelled,
          backgroundColor: Color(0xFFFFEBEE),
          foregroundColor: Color(0xFFC62828),
          description: 'تم رفض طلب الحجز',
        );

      default:
        return const BookingStatusUI(
          label: 'حالة غير معروفة',
          icon: Icons.help_outline_rounded,
          category: BookingStatusCategory.underReview,
          backgroundColor: Color(0xFFEEEEEE),
          foregroundColor: Color(0xFF616161),
          description: 'جاري تحديث بيانات الحالة',
        );
    }
  }

  /// Check if the booking belongs to upcoming journeys
  static bool isUpcoming(String status) {
    final cat = fromStatus(status).category;
    return cat == BookingStatusCategory.upcoming ||
        cat == BookingStatusCategory.actionRequired ||
        cat == BookingStatusCategory.underReview;
  }
}
