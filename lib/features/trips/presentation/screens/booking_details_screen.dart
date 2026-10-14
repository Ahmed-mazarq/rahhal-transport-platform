import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/booking.dart';
import '../utils/booking_status_ui.dart';

final driverInfoProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, driverId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  },
);

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tripRepo = ref.read(tripRepositoryProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تفاصيل الحجز',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<Booking?>(
        stream: tripRepo.watchBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'حدث خطأ في تحميل بيانات الحجز',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'الحجز غير موجود',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }

          final booking = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildStatusCard(isDark, booking),
              const SizedBox(height: 16),

              if (booking.status == 'confirmed') ...[
                _buildQrTicket(isDark, booking),
                const SizedBox(height: 16),
              ],

              _buildInfoSection(
                isDark,
                title: 'معلومات الرحلة',
                icon: Icons.directions_bus,
                children: [
                  _buildRow(
                    'رقم الحجز',
                    booking.bookingNumber.isNotEmpty
                        ? booking.bookingNumber
                        : booking.id.substring(0, 8).toUpperCase(),
                  ),
                  const Divider(),
                  _buildRow(
                    'مسار الرحلة',
                    '${booking.departureCity} ← ${booking.arrivalCity}',
                  ),
                  const Divider(),
                  _buildRow(
                    'تاريخ السفر',
                    DateFormat('dd MMMM yyyy', 'ar').format(booking.travelDate),
                  ),
                  const Divider(),
                  _buildRow(
                    'المقاعد المحجوزة',
                    booking.seatNumbers.isNotEmpty
                        ? booking.seatNumbers.join('، ')
                        : booking.seatNumber,
                  ),
                  const Divider(),
                  _buildRow('عدد الركاب', booking.seatCount.toInt().toString()),
                ],
              ),
              const SizedBox(height: 16),

              _buildDriverInfo(isDark, booking.driverId),
              const SizedBox(height: 16),

              _buildInfoSection(
                isDark,
                title: 'التفاصيل المالية',
                icon: Icons.receipt_long,
                children: [
                  _buildRow('إجمالي الرحلة', '${booking.price} ريال'),
                  const Divider(),
                  _buildRow(
                    'مبلغ تأكيد الحجز',
                    '${booking.depositAmount} ريال',
                    isBold: true,
                    color: const Color(0xFFF5A623),
                  ),
                  const Divider(),
                  _buildRow(
                    'المتبقي عند السفر',
                    '${booking.remainingAmount} ريال',
                    isBold: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildActionButtons(context, booking),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriverInfo(bool isDark, String driverId) {
    return Consumer(
      builder: (context, ref, child) {
        final driverAsyncValue = ref.watch(driverInfoProvider(driverId));
        return driverAsyncValue.when(
          data: (driverData) {
            final driverName =
                driverData?['fullName'] ?? driverData?['name'] ?? 'غير متوفر';
            final driverPhone = driverData?['phone'] ?? 'غير متوفر';
            return _buildInfoSection(
              isDark,
              title: 'معلومات السائق',
              icon: Icons.person,
              children: [
                _buildRow('اسم السائق', driverName),
                const Divider(),
                _buildRow(
                  'رقم التواصل',
                  driverPhone,
                  textDirection: TextDirection.ltr,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const SizedBox(),
        );
      },
    );
  }

  Widget _buildStatusCard(bool isDark, Booking booking) {
    final statusUI = BookingStatusUI.fromStatus(booking.status);
    final statusColor = statusUI.foregroundColor;
    final statusText = statusUI.label;
    final statusIcon = statusUI.icon;
    final description = statusUI.description;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (booking.status == 'pending_payment' &&
              booking.paymentDeadline != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            PaymentCountdownWidget(
              bookingId: booking.id,
              deadline: booking.paymentDeadline!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrTicket(bool isDark, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تذكرة إلكترونية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'جاهزة للصعود',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Icon(Icons.qr_code_2, size: 140, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'يرجى إبراز هذا الرمز للكابتن عند الصعود',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    bool isDark, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F3A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF0B1F3A), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    TextDirection? textDirection,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
              textAlign: TextAlign.left,
              textDirection: textDirection,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Booking booking) {
    final bool isExpired =
        booking.paymentDeadline != null &&
        DateTime.now().isAfter(booking.paymentDeadline!);
    if (booking.status == 'pending_payment' && !isExpired) {
      return ElevatedButton.icon(
        onPressed: () => context.push('/booking-payment/${booking.id}'),
        icon: const Icon(Icons.payment),
        label: const Text(
          'دفع مبلغ التأكيد',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: const Color(0xFF0B1F3A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      );
    }

    if (booking.status == 'payment_not_received') {
      return ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'سيتم التواصل معك من قبل فريق الدعم.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        },
        icon: const Icon(Icons.report_problem),
        label: const Text(
          'أبلغ عن مشكلة في الدفع',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if ([
      'pending_payment',
      'payment_verification',
      'awaiting_driver_verification',
      'confirmed',
    ].contains(booking.status)) {
      return Row(
        children: [
          if (booking.status == 'confirmed')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/track-trip/${booking.tripId}'),
                icon: const Icon(Icons.map),
                label: const Text(
                  'تتبع الرحلة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (booking.status == 'confirmed') const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/booking-chat', extra: booking),
              icon: const Icon(Icons.chat),
              label: const Text(
                'محادثة السائق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (booking.status == 'completed') {
      if (booking.isRated) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                booking.rating != null
                    ? 'تم تقييم الرحلة (${booking.rating!.toStringAsFixed(1)} نجوم)'
                    : 'تم تقييم هذه الرحلة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      } else {
        return ElevatedButton.icon(
          onPressed: () => context.push(
            '/rate-trip/${booking.tripId}',
            extra: {'bookingId': booking.id, 'driverId': booking.driverId},
          ),
          icon: const Icon(Icons.star_rate_rounded),
          label: const Text(
            'قيّم الرحلة الآن',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: const Color(0xFFF5A623),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}

class PaymentCountdownWidget extends ConsumerStatefulWidget {
  final String bookingId;
  final DateTime deadline;

  const PaymentCountdownWidget({
    super.key,
    required this.bookingId,
    required this.deadline,
  });

  @override
  ConsumerState<PaymentCountdownWidget> createState() =>
      _PaymentCountdownWidgetState();
}

class _PaymentCountdownWidgetState
    extends ConsumerState<PaymentCountdownWidget> {
  Timer? _timer;
  late Duration _remainingTime;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    if (now.isAfter(widget.deadline)) {
      if (mounted && !_isExpired) {
        setState(() {
          _remainingTime = Duration.zero;
          _isExpired = true;
        });
        _timer?.cancel();
        // Trigger expiration if we are still awaiting payment
        ref.read(tripRepositoryProvider).expireBooking(widget.bookingId);
      }
    } else {
      if (mounted) {
        setState(() {
          _remainingTime = widget.deadline.difference(now);
          _isExpired = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) return const SizedBox.shrink();

    return Column(
      children: [
        if (_remainingTime.inHours < 1)
          const Text(
            'تنبيه هام: بقي أقل من ساعة لإتمام الدفع! سيتم إلغاء الحجز قريبًا.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          )
        else if (_remainingTime.inHours < 6)
          const Text(
            'تنبيه: بقي أقل من 6 ساعات لإتمام الدفع.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          )
        else
          const Text(
            'تنبيه: يجب إتمام الدفع وإرسال إثبات التحويل خلال 24 ساعة، وإلا سيتم إلغاء الحجز وإتاحة المقاعد من جديد.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.orange,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'مهلة الدفع: 24 ساعة | متبقي: ${_formatDuration(_remainingTime)}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
  }
}
