import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/presentation/utils/booking_status_ui.dart';
import 'package:rahal/core/theme/admin_theme.dart';

class AdminBookingDetailsScreen extends ConsumerWidget {
  final Booking booking;

  const AdminBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'تفاصيل الحجز',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              title: 'معلومات الحجز الأساسية',
              icon: Icons.info_outline,
              children: [
                _buildRow(
                  'رقم الحجز:',
                  booking.bookingNumber.isNotEmpty
                      ? booking.bookingNumber
                      : (booking.id.length > 6
                            ? booking.id.substring(0, 6)
                            : booking.id),
                ),
                _buildRow('رقم المعرف الكامل:', booking.id),
                _buildRow(
                  'الحالة:',
                  _translateStatus(booking.status),
                  color: _getStatusColor(booking.status),
                ),
                _buildRow(
                  'تاريخ إنشاء الحجز:',
                  _formatDate(booking.createdAt ?? booking.bookingTime),
                ),
                _buildRow(
                  'آخر تحديث:',
                  _formatDate(
                    booking.updatedAt ??
                        booking.createdAt ??
                        booking.bookingTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'معلومات الرحلة',
              icon: Icons.directions_bus_outlined,
              children: [
                _buildRow('رقم الرحلة:', booking.tripId),
                _buildRow(
                  'مسار الرحلة:',
                  '${booking.departureCity} ➔ ${booking.arrivalCity}',
                ),
                _buildRow('تاريخ السفر:', _formatDate(booking.travelDate)),
                _buildRow(
                  'نقطة الانطلاق:',
                  booking.pickupPoint.isNotEmpty
                      ? booking.pickupPoint
                      : 'غير محدد',
                ),
                _buildRow(
                  'نقطة الوصول:',
                  booking.dropoffPoint.isNotEmpty
                      ? booking.dropoffPoint
                      : 'غير محدد',
                ),
                _buildRow(
                  'حالة الحضور:',
                  _translateAttendance(booking.attendanceStatus),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'معلومات المستخدمين',
              icon: Icons.people_outline,
              children: [
                _buildRow(
                  'اسم الراكب:',
                  booking.name.isNotEmpty ? booking.name : 'غير محدد',
                ),
                _buildRow('معرف الراكب:', booking.passengerId),
                const Divider(),
                _buildRow(
                  'اسم السائق:',
                  booking.driverName.isNotEmpty
                      ? booking.driverName
                      : 'غير محدد',
                ),
                _buildRow('معرف السائق:', booking.driverId),
                _buildRow(
                  'المركبة:',
                  booking.vehiclePlate.isNotEmpty
                      ? booking.vehiclePlate
                      : 'غير محدد',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'معلومات الدفع والتسعير',
              icon: Icons.payment_outlined,
              children: [
                _buildRow('المقاعد المحجوزة:', booking.seatNumbers.join('، ')),
                _buildRow('عدد المقاعد:', booking.seatCount.toString()),
                _buildRow(
                  'السعر الإجمالي:',
                  '${booking.price} ر.س',
                  color: Colors.green,
                ),
                _buildRow(
                  'حالة الدفع:',
                  _translatePaymentStatus(booking.paymentStatus),
                ),
                if (booking.depositAmount > 0)
                  _buildRow('العربون المدفوع:', '${booking.depositAmount} ر.س'),
                if (booking.remainingAmount > 0)
                  _buildRow(
                    'المبلغ المتبقي:',
                    '${booking.remainingAmount} ر.س',
                  ),
                if (booking.transactionReference.isNotEmpty)
                  _buildRow('رقم المرجع:', booking.transactionReference),
                if (booking.senderName.isNotEmpty)
                  _buildRow('اسم المحول:', booking.senderName),
                if (booking.transferAmount > 0)
                  _buildRow('مبلغ التحويل:', '${booking.transferAmount} ر.س'),
                if (booking.transferSubmittedAt != null)
                  _buildRow(
                    'وقت التحويل:',
                    _formatDate(booking.transferSubmittedAt!),
                  ),
              ],
            ),
            if (booking.paymentProofUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'إثبات التحويل',
                icon: Icons.image_outlined,
                children: [
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      booking.paymentProofUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text(
                              'تعذر تحميل إثبات الدفع',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (booking.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'ملاحظات',
                icon: Icons.note_alt_outlined,
                children: [
                  Text(
                    booking.notes,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AdminTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AdminTheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: color ?? Colors.black,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _translateStatus(String status) {
    if (status == 'refunded') return 'مستردة';
    return BookingStatusUI.fromStatus(status).label;
  }

  Color _getStatusColor(String status) {
    if (status == 'refunded') return Colors.orange;
    return BookingStatusUI.fromStatus(status).foregroundColor;
  }

  String _translatePaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'unpaid':
        return 'غير مدفوع';
      case 'pending_driver_verification':
        return 'بانتظار تحقق السائق';
      case 'deposit_verified':
        return 'تم التحقق من العربون';
      case 'refunded':
        return 'مسترد';
      default:
        return 'معلق';
    }
  }

  String _translateAttendance(String status) {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غائب';
      case 'late':
        return 'متأخر';
      case 'cancelled':
        return 'ملغى';
      case 'no_show':
        return 'لم يحضر';
      default:
        return 'غير مسجل';
    }
  }
}
