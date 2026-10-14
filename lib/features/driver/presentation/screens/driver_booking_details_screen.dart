import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../trips/domain/models/booking.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../widgets/driver_passenger_card.dart';

class DriverBookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DriverBookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DriverBookingDetailsScreen> createState() =>
      _DriverBookingDetailsScreenState();
}

class _DriverBookingDetailsScreenState
    extends ConsumerState<DriverBookingDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _confirmPayment(String bookingId, String driverId) async {
    setState(() => _isProcessing = true);
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      await tripRepo.confirmBookingDeposit(bookingId, driverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تأكيد استلام المبلغ بنجاح.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تأكيد استلام المبلغ.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectPayment(String bookingId, String driverId) async {
    final reasonController = TextEditingController();
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رفض الدفع', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'هل أنت متأكد من أن المبلغ لم يصلك؟',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'السبب (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'تأكيد الرفض',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final tripRepo = ref.read(tripRepositoryProvider);
        await tripRepo.rejectPaymentVerification(
          bookingId,
          driverId,
          reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تسجيل عدم استلام المبلغ.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر تسجيل العملية.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentProof(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String? signedUrl;
        bool isLoadingImage = booking.paymentProofUrl.startsWith('private://');
        bool hasError = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void fetchUrl() {
              final storageService = SupabaseStorageService();
              storageService
                  .getPaymentProofSignedUrl(booking.id, booking.paymentProofUrl)
                  .then((url) {
                    if (url.isNotEmpty) {
                      setModalState(() {
                        signedUrl = url;
                        isLoadingImage = false;
                      });
                    } else {
                      setModalState(() {
                        hasError = true;
                        isLoadingImage = false;
                      });
                    }
                  })
                  .catchError((e) {
                    setModalState(() {
                      hasError = true;
                      isLoadingImage = false;
                    });
                  });
            }

            if (isLoadingImage && signedUrl == null && !hasError) {
              fetchUrl();
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'إثبات التحويل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (booking.paymentProofUrl.isNotEmpty)
                      if (booking.paymentProofUrl.startsWith(
                            'LOCAL_DEVELOPMENT',
                          ) ||
                          booking.paymentProofUrl.startsWith('data:image'))
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'تم إرفاق إثبات الدفع (وضع التطوير)',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (isLoadingImage)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        )
                      else if (hasError)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'تعذر الوصول إلى خدمة عرض إثبات الدفع',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    hasError = false;
                                    isLoadingImage = true;
                                  });
                                  fetchUrl();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text(
                                  'إعادة المحاولة',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: signedUrl ?? booking.paymentProofUrl,
                            height: 300,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'لم يتم إرسال إثبات التحويل بعد',
                          style: TextStyle(fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'اسم المرسل',
                      booking.senderName.isNotEmpty
                          ? booking.senderName
                          : 'غير متوفر',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'المبلغ المحول',
                      '${booking.transferAmount} ريال',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'رقم العملية',
                      booking.transactionReference.isNotEmpty
                          ? booking.transactionReference
                          : 'غير متوفر',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'تاريخ التحويل',
                      booking.transferSubmittedAt != null
                          ? DateFormat(
                              'yyyy-MM-dd hh:mm a',
                              'ar',
                            ).format(booking.transferSubmittedAt!)
                          : 'غير متوفر',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripRepo = ref.read(tripRepositoryProvider);
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تفاصيل الحجز',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
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
                  'حدث خطأ في تحميل الحجز',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }
            final booking = snapshot.data;
            if (booking == null) {
              return const Center(
                child: Text(
                  'الحجز غير موجود',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }

            if (currentUserUid == null || booking.driverId != currentUserUid) {
              return const Center(
                child: Text(
                  'لا تملك صلاحية عرض هذا الحجز',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final bookingNumber = booking.bookingNumber.isNotEmpty
                ? booking.bookingNumber
                : booking.id.substring(0, 8).toUpperCase();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // A. BOOKING HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'طلب حجز / تفاصيل الحجز',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStatusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'رقم الحجز: $bookingNumber',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // B. PASSENGER INFORMATION
                const Text(
                  'بيانات الراكب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                DriverPassengerCard(
                  booking: booking,
                  onMessage: () {
                    // Assuming booking-chat accepts booking object, otherwise pass ID safely if needed
                    context.push('/booking-chat', extra: booking);
                  },
                ),
                const SizedBox(height: 24),

                // C. TRIP INFORMATION
                const Text(
                  'معلومات الرحلة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'مسار الرحلة',
                          '${booking.departureCity.isNotEmpty ? booking.departureCity : 'غير متوفر'} ← ${booking.arrivalCity.isNotEmpty ? booking.arrivalCity : 'غير متوفر'}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'تاريخ السفر',
                          DateFormat('yyyy-MM-dd').format(booking.travelDate),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'وقت إنشاء الحجز',
                          DateFormat(
                            'yyyy-MM-dd hh:mm a',
                            'ar',
                          ).format(booking.bookingTime),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'رقم الرحلة',
                          booking.tripId.isNotEmpty
                              ? booking.tripId
                              : 'غير متوفر',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'اسم السائق',
                          booking.driverName.isNotEmpty
                              ? booking.driverName
                              : 'غير متوفر',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'لوحة المركبة',
                          booking.vehiclePlate.isNotEmpty
                              ? booking.vehiclePlate
                              : 'غير متوفر',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'المقاعد',
                          booking.seatNumbers.isNotEmpty
                              ? booking.seatNumbers.join(', ')
                              : booking.seatNumber.isNotEmpty
                              ? booking.seatNumber
                              : 'غير متوفر',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'عدد الركاب',
                          booking.seatCount.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // D. FINANCIAL DETAILS
                const Text(
                  'التفاصيل المالية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'إجمالي قيمة الرحلة',
                          '${booking.price.toInt()} ${booking.currency.isNotEmpty ? booking.currency : "YER"}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'مبلغ تأكيد الحجز',
                          '${booking.depositAmount.toInt()} ${booking.currency.isNotEmpty ? booking.currency : "YER"}',
                          valueColor: Colors.orange,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'المتبقي عند السفر',
                          '${booking.remainingAmount.toInt()} ${booking.currency.isNotEmpty ? booking.currency : "YER"}',
                          valueColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // E. PAYMENT STATUS & G. PAYMENT DEADLINE
                const Text(
                  'حالة الحجز والدفع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusRow('حالة الحجز', booking.status),
                        const Divider(),
                        _buildStatusRow('حالة الدفع', booking.paymentStatus),
                        if (booking.depositConfirmed) ...[
                          const Divider(),
                          _buildInfoRow(
                            'تأكيد الدفع',
                            'تم الاستلام',
                            valueColor: Colors.green,
                          ),
                        ],
                        if (booking.paymentDeadline != null &&
                            (booking.status == 'pending_payment' ||
                                booking.status == 'awaiting_payment')) ...[
                          const Divider(),
                          _buildInfoRow(
                            'مهلة تأكيد الحجز',
                            booking.paymentDeadline!.isBefore(DateTime.now())
                                ? 'انتهت مهلة الدفع'
                                : DateFormat(
                                    'yyyy-MM-dd hh:mm a',
                                    'ar',
                                  ).format(booking.paymentDeadline!),
                            valueColor:
                                booking.paymentDeadline!.isBefore(
                                  DateTime.now(),
                                )
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // H. PAYMENT VERIFICATION ACTIONS & F. PAYMENT PROOF
                if (booking.status == 'payment_verification' ||
                    booking.status == 'awaiting_driver_verification') ...[
                  Card(
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'قام الراكب بإرسال إثبات تحويل.\nتحقق من حسابك البنكي أو محفظتك قبل تأكيد الاستلام.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _showPaymentProof(booking),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text(
                              'عرض إثبات التحويل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isProcessing)
                            const CircularProgressIndicator()
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _confirmPayment(
                                      booking.id,
                                      booking.driverId,
                                    ),
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'تم استلام مبلغ الحجز',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          if (!_isProcessing)
                            TextButton.icon(
                              onPressed: () =>
                                  _rejectPayment(booking.id, booking.driverId),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text(
                                'لم يصل المبلغ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else if (booking.paymentProofUrl.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showPaymentProof(booking),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text(
                      'عرض إثبات التحويل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // I. PAYMENT VERIFICATION HISTORY
                if (booking.paymentVerifiedAt != null ||
                    booking.paymentRejectedAt != null) ...[
                  const Text(
                    'سجل الدفع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (booking.paymentVerifiedAt != null) ...[
                            _buildInfoRow(
                              'تم تأكيد الاستلام',
                              DateFormat(
                                'yyyy-MM-dd hh:mm a',
                                'ar',
                              ).format(booking.paymentVerifiedAt!),
                            ),
                          ],
                          if (booking.paymentRejectedAt != null) ...[
                            if (booking.paymentVerifiedAt != null)
                              const Divider(),
                            _buildInfoRow(
                              'تم الرفض في',
                              DateFormat(
                                'yyyy-MM-dd hh:mm a',
                                'ar',
                              ).format(booking.paymentRejectedAt!),
                              valueColor: Colors.red,
                            ),
                            if (booking.paymentRejectionReason.isNotEmpty) ...[
                              const Divider(),
                              _buildInfoRow(
                                'سبب الرفض',
                                booking.paymentRejectionReason,
                                valueColor: Colors.red,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // J. ATTENDANCE
                if (booking.status == 'confirmed' &&
                    booking.attendanceStatus.isNotEmpty) ...[
                  const Text(
                    'سجل الحضور',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatusRow('التحضير', booking.attendanceStatus),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String text;
    Color color;
    switch (status) {
      case 'awaiting_payment':
      case 'pending_payment':
        text = 'بانتظار الدفع';
        color = Colors.orange;
        break;
      case 'awaiting_driver_verification':
      case 'payment_verification':
        text = 'طلب تأكيد تحويل';
        color = Colors.blue;
        break;
      case 'confirmed':
        text = 'مؤكد';
        color = Colors.green;
        break;
      case 'support_review':
        text = 'نزاع قيد المراجعة';
        color = Colors.purple;
        break;
      case 'expired':
        text = 'منتهي';
        color = Colors.red;
        break;
      case 'rejected':
        text = 'مرفوض';
        color = Colors.red;
        break;
      case 'cancelled':
        text = 'ملغي';
        color = Colors.red;
        break;
      case 'completed':
        text = 'مكتمل';
        color = Colors.teal;
        break;
      default:
        text = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    String text;
    Color color;
    switch (status) {
      case 'awaiting_payment':
      case 'pending_payment':
      case 'pending':
        text = 'بانتظار الدفع';
        color = Colors.orange;
        break;
      case 'awaiting_driver_verification':
      case 'payment_verification':
      case 'verification':
        text = 'قيد التحقق';
        color = Colors.blue;
        break;
      case 'confirmed':
      case 'received':
        text = 'مؤكد';
        color = Colors.green;
        break;
      case 'support_review':
      case 'disputed':
        text = 'نزاع قيد المراجعة';
        color = Colors.purple;
        break;
      case 'expired':
        text = 'منتهي';
        color = Colors.red;
        break;
      case 'rejected':
      case 'failed':
        text = 'مرفوض';
        color = Colors.red;
        break;
      case 'cancelled':
        text = 'ملغي';
        color = Colors.red;
        break;
      case 'completed':
        text = 'مكتمل';
        color = Colors.teal;
        break;
      case 'present':
        text = 'حضر';
        color = Colors.green;
        break;
      case 'absent':
        text = 'لم يحضر';
        color = Colors.red;
        break;
      case 'late':
        text = 'متأخر';
        color = Colors.orange;
        break;
      case 'unregistered':
        text = 'لم يتم التسجيل';
        color = Colors.grey;
        break;
      default:
        text = status;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
          ),
          Row(
            children: [
              Icon(Icons.circle, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
