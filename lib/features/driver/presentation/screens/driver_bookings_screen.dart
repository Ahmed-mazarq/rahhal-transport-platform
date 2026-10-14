import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/models/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../parcel/domain/models/parcel_delivery.dart';
import '../../../parcel/presentation/providers/parcel_provider.dart';
import '../widgets/driver_booking_card.dart';

class DriverBookingsScreen extends ConsumerStatefulWidget {
  const DriverBookingsScreen({super.key});

  @override
  ConsumerState<DriverBookingsScreen> createState() =>
      _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends ConsumerState<DriverBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _showParcels = false;
  int _parcelTab = 0; // 0: My Parcels, 1: Marketplace

  final List<String> _tabs = [
    'الكل',
    'يتطلب إجراء',
    'قيد الانتظار',
    'مؤكدة',
    'مكتملة',
    'ملغاة',
    'نزاعات',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAttendance(String bookingId, String attendance) async {
    try {
      await ref
          .read(tripRepositoryProvider)
          .updateBookingAttendance(bookingId, attendance);
      if (attendance == 'no_show') {
        await ref
            .read(tripRepositoryProvider)
            .updateBookingStatus(
              bookingId,
              'completed',
            ); // Or handle no_show differently
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحديث حالة الحضور، يرجى المحاولة لاحقاً',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateParcelStatus(
    String parcelId,
    String newStatus, {
    String? pinToVerify,
    String? actualPin,
  }) async {
    if (newStatus == 'delivered') {
      if (pinToVerify == null || pinToVerify != actualPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'رمز التحقق غير صحيح!',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
        return;
      }
    }

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    final success = await ref
        .read(parcelActionProvider.notifier)
        .updateStatus(
          parcelId,
          newStatus,
          authState.user.id,
          'driver',
          'تم تحديث حالة الطرد إلى $newStatus',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تحديث حالة الطرد بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      // Invalidate the parcels provider to refresh the list
      ref.invalidate(driverParcelsProvider(authState.user.id));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء التحديث',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }
  }

  void _showRejectDialog(String parcelId) {
    String? selectedReason = 'المساحة غير كافية';
    final customReasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('سبب الرفض', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items:
                    [
                          'المساحة غير كافية',
                          'الوزن ثقيل جداً',
                          'الوقت غير مناسب',
                          'المسار غير مطابق',
                          'أخرى',
                        ]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setDialogState(() => selectedReason = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              if (selectedReason == 'أخرى') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: customReasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اكتب السبب...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final reason = selectedReason == 'أخرى'
                    ? customReasonCtrl.text
                    : selectedReason!;
                Navigator.pop(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final authState = ref.read(authProvider);
                if (authState is! Authenticated) return;

                final success = await ref
                    .read(parcelActionProvider.notifier)
                    .rejectParcel(parcelId, authState.user.id, reason);

                if (success && mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم رفض الطرد',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                  ref.invalidate(driverParcelsProvider(authState.user.id));
                }
              },
              child: const Text('تأكيد الرفض'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinDialog(String parcelId, String actualPin) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إدخال رمز التحقق (PIN)',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'رمز المستلم (4 أرقام)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateParcelStatus(
                parcelId,
                'delivered',
                pinToVerify: ctrl.text,
                actualPin: actualPin,
              );
            },
            child: const Text('تأكيد التسليم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'الحجوزات والطرود',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showParcels ? Icons.directions_car : Icons.local_shipping,
            ),
            tooltip: _showParcels ? 'عرض الركاب' : 'عرض الطرود',
            onPressed: () {
              setState(() {
                _showParcels = !_showParcels;
              });
            },
          ),
        ],
        bottom: _showParcels
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryColor,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
      ),
      body: _showParcels
          ? _buildParcelsList()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList([]), // All
                _buildBookingsList([
                  'payment_verification',
                  'awaiting_driver_verification',
                  'support_review',
                  'refund_review',
                ]),
                _buildBookingsList([
                  'pending',
                  'pending_payment',
                  'awaiting_payment',
                ]),
                _buildBookingsList(['confirmed', 'accepted']),
                _buildBookingsList(['completed']),
                _buildBookingsList([
                  'cancelled',
                  'rejected',
                  'expired',
                  'cancelled_by_passenger',
                  'cancelled_by_driver',
                  'payment_not_received',
                ]),
                _buildBookingsList(['support_review', 'refund_review']),
              ],
            ),
    );
  }

  Widget _buildParcelsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text(
                  'طرودي المسندة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              ButtonSegment(
                value: 1,
                label: Text(
                  'سوق الطرود',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
            selected: {_parcelTab},
            onSelectionChanged: (set) => setState(() => _parcelTab = set.first),
          ),
        ),
        Expanded(
          child: _parcelTab == 0
              ? _buildDriverParcels()
              : _buildMarketplaceParcels(),
        ),
      ],
    );
  }

  Widget _buildDriverParcels() {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final parcelsAsync = ref.watch(driverParcelsProvider(authState.user.id));

    return parcelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(
        child: Text(
          'تعذر تحميل طلبات الطرود',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        ),
      ),
      data: (parcels) {
        if (parcels.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد طلبات طرود',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parcels.length,
          itemBuilder: (context, index) {
            return _buildParcelCard(parcels[index]);
          },
        );
      },
    );
  }

  Widget _buildMarketplaceParcels() {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final parcelsAsync = ref.watch(
      matchedMarketplaceParcelsProvider(authState.user.id),
    );

    return parcelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(
        child: Text(
          'تعذر تحميل طرود السوق',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        ),
      ),
      data: (matchedParcels) {
        if (matchedParcels.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد طلبات طرود في السوق حالياً',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matchedParcels.length,
          itemBuilder: (context, index) {
            final match = matchedParcels[index];
            return _buildParcelCard(
              match.parcel,
              isMarketplace: true,
              matchReason: match.matchReason,
            );
          },
        );
      },
    );
  }

  Widget _buildParcelCard(
    ParcelDelivery parcel, {
    bool isMarketplace = false,
    String? matchReason,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طرد: ${parcel.trackingNumber}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildParcelStatusBadge(parcel.status),
            ],
          ),
          const Divider(height: 16),
          _buildDetailRow(
            Icons.route,
            'المسار',
            '${parcel.originDistrict != null && parcel.originDistrict!.isNotEmpty ? "${parcel.originDistrict}، " : ""}${parcel.originCity} -> ${parcel.destinationDistrict != null && parcel.destinationDistrict!.isNotEmpty ? "${parcel.destinationDistrict}، " : ""}${parcel.destinationCity}',
          ),
          _buildDetailRow(
            Icons.person,
            'المرسل',
            '${parcel.senderName} - ${parcel.senderPhone}',
          ),
          _buildDetailRow(
            Icons.person_outline,
            'المستلم',
            '${parcel.receiverName} - ${parcel.receiverPhone}',
          ),
          _buildDetailRow(
            Icons.inventory_2_outlined,
            'المحتوى',
            '${parcel.category} (${parcel.weight} كجم)',
          ),
          if (parcel.isFragile)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'قابل للكسر',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.orange),
                  ),
                ],
              ),
            ),
          _buildDetailRow(
            Icons.attach_money,
            'السعر',
            '${parcel.price} ${parcel.currency}',
          ),

          if (parcel.status == 'rejected' && parcel.rejectionReason != null)
            _buildDetailRow(
              Icons.cancel,
              'سبب الرفض',
              parcel.rejectionReason!,
              color: Colors.red,
            ),

          if (isMarketplace && matchReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    matchReason == 'مطابق لمسارك'
                        ? Icons.check_circle
                        : (matchReason == 'يمر عبر مسارك'
                              ? Icons.check_circle_outline
                              : Icons.info_outline),
                    color:
                        matchReason == 'مطابق لمسارك' ||
                            matchReason == 'يمر عبر مسارك'
                        ? Colors.green
                        : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'سبب المطابقة: $matchReason',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color:
                          matchReason == 'مطابق لمسارك' ||
                              matchReason == 'يمر عبر مسارك'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          _buildParcelActions(
            parcel.id,
            parcel.status,
            parcel.deliveryVerificationCode ?? '',
            isMarketplace,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color color = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: color == Colors.grey ? Colors.black87 : color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status;
    switch (status) {
      case 'pending_carrier_acceptance':
        color = Colors.orange;
        text = 'بانتظار القبول';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'تم القبول';
        break;
      case 'awaiting_pickup':
        color = Colors.purple;
        text = 'بانتظار الاستلام';
        break;
      case 'picked_up':
        color = Colors.deepPurple;
        text = 'تم الاستلام';
        break;
      case 'in_transit':
        color = Colors.indigo;
        text = 'في الطريق';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'تم التسليم';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ملغى';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParcelActions(
    String id,
    String status,
    String actualPin,
    bool isMarketplace,
  ) {
    if (isMarketplace && status == 'searching_for_carrier') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final authState = ref.read(authProvider);
            if (authState is! Authenticated) return;

            final success = await ref
                .read(parcelActionProvider.notifier)
                .acceptParcel(id, authState.user.id, authState.user.fullName);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم قبول الطرد بنجاح!',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              );
              ref.invalidate(marketplaceParcelsProvider);
              ref.invalidate(driverParcelsProvider(authState.user.id));
            } else if (mounted) {
              final error =
                  ref.read(parcelActionProvider).error?.toString() ??
                  'حدث خطأ غير معروف';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('قبول ونقل الطرد'),
        ),
      );
    }

    if (status == 'pending_carrier_acceptance') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateParcelStatus(id, 'accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('قبول'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(id),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('رفض'),
            ),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateParcelStatus(id, 'awaiting_pickup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('الذهاب للاستلام'),
        ),
      );
    } else if (status == 'awaiting_pickup') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateParcelStatus(id, 'picked_up'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('تم استلام الطرد من المرسل'),
        ),
      );
    } else if (status == 'picked_up') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateParcelStatus(id, 'in_transit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text('بدء التوصيل (في الطريق)'),
        ),
      );
    } else if (status == 'in_transit') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showPinDialog(id, actualPin),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('تسليم للمستلم (مطلوب PIN)'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _normalizeBookingStatus(String status) {
    switch (status) {
      case 'awaiting_payment':
        return 'pending_payment';
      case 'awaiting_driver_verification':
        return 'payment_verification';
      case 'payment_not_received':
        return 'support_review';
      default:
        return status;
    }
  }

  Widget _buildBookingsList(List<String> validStatuses) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final tripRepo = ref.watch(tripRepositoryProvider);

    // PART 3: Use the authoritative Firebase UID for driver queries
    final driverUid =
        FirebaseAuth.instance.currentUser?.uid ?? authState.user.uid;

    return StreamBuilder<List<Booking>>(
      stream: tripRepo.watchDriverBookings(driverUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء تحميل الحجوزات'));
        }

        final bookings = snapshot.data ?? [];

        final filtered = bookings.where((b) {
          final normalizedStatus = _normalizeBookingStatus(b.status);

          if (validStatuses.isEmpty) return true;

          // Safe fallback for unlisted dispute/review states
          if (![
            'pending_payment',
            'payment_verification',
            'confirmed',
            'completed',
            'cancelled',
            'rejected',
            'expired',
            'support_review',
            'refund_review',
          ].contains(normalizedStatus)) {
            if (validStatuses.contains('support_review')) return true;
          }

          return validStatuses.contains(normalizedStatus);
        }).toList();

        filtered.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد حجوزات في هذه القائمة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final booking = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DriverBookingCard(
                booking: booking,
                onAccept: () {
                  context.push('/driver-booking-details/${booking.id}');
                },
                onReject: () {
                  ref
                      .read(tripRepositoryProvider)
                      .updateBookingStatus(booking.id, 'rejected');
                },
                onMessage: () {
                  context.push('/booking-chat', extra: booking);
                },
                onViewDetails: () {
                  context.push('/driver-booking-details/${booking.id}');
                },
                onMarkAttendance: (attendance) {
                  _markAttendance(booking.id, attendance);
                },
              ),
            );
          },
        );
      },
    );
  }
}
