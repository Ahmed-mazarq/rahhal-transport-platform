import 'package:flutter/material.dart';
import 'package:rahal/features/trips/presentation/utils/booking_status_ui.dart';

/// Centralized UI Presentation Mappers for Driver Experience (Part 57)

class DriverTripStatusUi {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const DriverTripStatusUi({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  static DriverTripStatusUi fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const DriverTripStatusUi(
          label: 'مسودة',
          icon: Icons.edit_note_rounded,
          foregroundColor: Color(0xFF616161),
          backgroundColor: Color(0xFFEEEEEE),
        );
      case 'published':
        return const DriverTripStatusUi(
          label: 'منشورة',
          icon: Icons.publish_rounded,
          foregroundColor: Color(0xFF1565C0),
          backgroundColor: Color(0xFFE3F2FD),
        );
      case 'open_for_booking':
      case 'available':
        return const DriverTripStatusUi(
          label: 'متاحة للحجز',
          icon: Icons.event_available_rounded,
          foregroundColor: Color(0xFF2E7D32),
          backgroundColor: Color(0xFFE8F5E9),
        );
      case 'running':
      case 'active':
      case 'started':
        return const DriverTripStatusUi(
          label: 'جارية',
          icon: Icons.directions_car_filled_rounded,
          foregroundColor: Color(0xFFE65100),
          backgroundColor: Color(0xFFFFF3E0),
        );
      case 'completed':
      case 'finished':
        return const DriverTripStatusUi(
          label: 'مكتملة',
          icon: Icons.check_circle_rounded,
          foregroundColor: Color(0xFF00695C),
          backgroundColor: Color(0xFFE0F2F1),
        );
      case 'cancelled':
        return const DriverTripStatusUi(
          label: 'ملغاة',
          icon: Icons.cancel_rounded,
          foregroundColor: Color(0xFFC62828),
          backgroundColor: Color(0xFFFFEBEE),
        );
      default:
        return DriverTripStatusUi(
          label: status.isEmpty ? 'غير محدد' : status,
          icon: Icons.info_outline_rounded,
          foregroundColor: const Color(0xFF757575),
          backgroundColor: const Color(0xFFF5F5F5),
        );
    }
  }
}

/// Delegates directly to the shared canonical BookingStatusUI so Driver & Passenger stay 100% unified
class DriverBookingStatusUi {
  DriverBookingStatusUi._();

  static BookingStatusUI fromStatus(String status) {
    return BookingStatusUI.fromStatus(status);
  }

  static BookingStatusUI info(String status) => fromStatus(status);
}

class DriverAccountStatusUi {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String description;

  const DriverAccountStatusUi({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.description,
  });

  static DriverAccountStatusUi fromStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return const DriverAccountStatusUi(
          label: 'حساب معتمد ومفعل',
          icon: Icons.verified_rounded,
          color: Color(0xFF2E7D32),
          backgroundColor: Color(0xFFE8F5E9),
          description: 'حسابك معتمد وجاهز لاستقبال الرحلات والطلبات',
        );
      case 'pending_review':
      case 'pending':
        return const DriverAccountStatusUi(
          label: 'قيد المراجعة والتدقيق',
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFF57F17),
          backgroundColor: Color(0xFFFFF8E1),
          description: 'يجري تدقيق مستنداتك من قِبل إدارة رحال',
        );
      case 'need_modification':
        return const DriverAccountStatusUi(
          label: 'مطلوب تعديل المستندات',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFE65100),
          backgroundColor: Color(0xFFFFF3E0),
          description: 'يرجى مراجعة وتحديث الوثائق المطلوبة',
        );
      case 'rejected':
        return const DriverAccountStatusUi(
          label: 'طلب الحساب مرفوض',
          icon: Icons.cancel_rounded,
          color: Color(0xFFC62828),
          backgroundColor: Color(0xFFFFEBEE),
          description: 'تم رفض طلب الانضمام، تواصل مع فريق الدعم',
        );
      case 'suspended':
      case 'blocked':
        return const DriverAccountStatusUi(
          label: 'الحساب موقوف مؤقتاً',
          icon: Icons.block_rounded,
          color: Color(0xFFC62828),
          backgroundColor: Color(0xFFFFEBEE),
          description: 'تم إيقاف الحساب من قِبل الإدارة',
        );
      default:
        return const DriverAccountStatusUi(
          label: 'استكمال التسجيل',
          icon: Icons.edit_note_rounded,
          color: Color(0xFF1565C0),
          backgroundColor: Color(0xFFE3F2FD),
          description: 'يرجى إكمال بيانات ووثائق السائق للمراجعة',
        );
    }
  }
}

class VehicleStatusUi {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  Color get textColor => color;
  Color get borderColor => color.withValues(alpha: 0.35);

  const VehicleStatusUi({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  static VehicleStatusUi fromStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return const VehicleStatusUi(
          label: 'جاهزة للخدمة',
          icon: Icons.check_circle_rounded,
          color: Color(0xFF2E7D32),
          backgroundColor: Color(0xFFE8F5E9),
        );
      case 'maintenance':
        return const VehicleStatusUi(
          label: 'تحت الصيانة',
          icon: Icons.build_rounded,
          color: Color(0xFFF57F17),
          backgroundColor: Color(0xFFFFF8E1),
        );
      case 'inactive':
      default:
        return const VehicleStatusUi(
          label: 'متوقفة',
          icon: Icons.pause_circle_rounded,
          color: Color(0xFF757575),
          backgroundColor: Color(0xFFEEEEEE),
        );
    }
  }
}

class DocumentStatusUi {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const DocumentStatusUi({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  static DocumentStatusUi fromStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return const DocumentStatusUi(
          label: 'معتمد',
          icon: Icons.check_circle_rounded,
          color: Color(0xFF2E7D32),
          backgroundColor: Color(0xFFE8F5E9),
        );
      case 'pending':
        return const DocumentStatusUi(
          label: 'قيد التدقيق',
          icon: Icons.hourglass_empty_rounded,
          color: Color(0xFFF57F17),
          backgroundColor: Color(0xFFFFF8E1),
        );
      case 'needs_update':
        return const DocumentStatusUi(
          label: 'يتطلب تحديث',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFE65100),
          backgroundColor: Color(0xFFFFF3E0),
        );
      case 'expired':
        return const DocumentStatusUi(
          label: 'منتهي الصلاحية',
          icon: Icons.timer_off_rounded,
          color: Color(0xFFC62828),
          backgroundColor: Color(0xFFFFEBEE),
        );
      case 'rejected':
        return const DocumentStatusUi(
          label: 'مرفوض',
          icon: Icons.cancel_rounded,
          color: Color(0xFFC62828),
          backgroundColor: Color(0xFFFFEBEE),
        );
      default:
        return const DocumentStatusUi(
          label: 'غير مكتمل',
          icon: Icons.help_outline_rounded,
          color: Color(0xFF757575),
          backgroundColor: Color(0xFFEEEEEE),
        );
    }
  }
}

class ParcelStatusUi {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const ParcelStatusUi({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  static ParcelStatusUi fromStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
      case 'pending':
        return const ParcelStatusUi(
          label: 'متاح للنقل',
          icon: Icons.inventory_2_outlined,
          color: Color(0xFF1565C0),
          backgroundColor: Color(0xFFE3F2FD),
        );
      case 'assigned':
      case 'accepted':
        return const ParcelStatusUi(
          label: 'تم القبول',
          icon: Icons.handshake_rounded,
          color: Color(0xFFF57F17),
          backgroundColor: Color(0xFFFFF8E1),
        );
      case 'picked_up':
      case 'in_transit':
        return const ParcelStatusUi(
          label: 'قيد التوصيل',
          icon: Icons.local_shipping_rounded,
          color: Color(0xFFE65100),
          backgroundColor: Color(0xFFFFF3E0),
        );
      case 'delivered':
        return const ParcelStatusUi(
          label: 'تم التسليم',
          icon: Icons.task_alt_rounded,
          color: Color(0xFF2E7D32),
          backgroundColor: Color(0xFFE8F5E9),
        );
      case 'cancelled':
        return const ParcelStatusUi(
          label: 'ملغي',
          icon: Icons.cancel_outlined,
          color: Color(0xFFC62828),
          backgroundColor: Color(0xFFFFEBEE),
        );
      default:
        return ParcelStatusUi(
          label: status ?? 'غير محدد',
          icon: Icons.info_outline,
          color: const Color(0xFF757575),
          backgroundColor: const Color(0xFFEEEEEE),
        );
    }
  }
}
