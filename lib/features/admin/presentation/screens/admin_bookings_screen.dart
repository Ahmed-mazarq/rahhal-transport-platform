import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_operations_provider.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/presentation/utils/booking_status_ui.dart';
import 'package:rahal/core/providers/repository_providers.dart';
import 'package:rahal/core/theme/admin_theme.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 11, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة الحجوزات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: AdminTheme.primary,
          indicatorColor: AdminTheme.primary,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'تحتاج إجراء'),
            Tab(text: 'بانتظار الدفع'),
            Tab(text: 'قيد التحقق'),
            Tab(text: 'بانتظار تأكيد السائق'),
            Tab(text: 'مؤكدة'),
            Tab(text: 'جارية'),
            Tab(text: 'مكتملة'),
            Tab(text: 'ملغاة'),
            Tab(text: 'مرفوضة'),
            Tab(text: 'مستردة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookingsTabView(status: null), // الكل
          _BookingsTabView(status: 'needs_action'), // تحتاج إجراء
          _BookingsTabView(
            status: 'awaiting_payment',
            usePaymentStatus: true,
          ), // بانتظار الدفع
          _BookingsTabView(
            status: 'payment_verification',
            usePaymentStatus: true,
          ), // قيد التحقق
          _BookingsTabView(
            status: 'awaiting_driver_verification',
          ), // بانتظار تأكيد السائق
          _BookingsTabView(status: 'confirmed'), // مؤكدة
          _BookingsTabView(status: 'running'), // جارية
          _BookingsTabView(status: 'completed'), // مكتملة
          _BookingsTabView(status: 'cancelled'), // ملغاة
          _BookingsTabView(status: 'rejected'), // مرفوضة
          _BookingsTabView(
            status: 'refunded',
            usePaymentStatus: true,
          ), // مستردة
        ],
      ),
    );
  }
}

class _BookingsTabView extends ConsumerWidget {
  final String? status;
  final bool usePaymentStatus;
  const _BookingsTabView({required this.status, this.usePaymentStatus = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    dynamic getFirestoreStatus(String? uiStatus) {
      if (uiStatus == null) return null;
      switch (uiStatus) {
        case 'needs_action':
          return const ['pending', 'support_review'];
        case 'awaiting_payment':
          return const [
            'awaiting_payment',
            'pending_payment',
            'pending',
          ]; // paymentStatus
        case 'payment_verification':
          return const [
            'payment_verification',
            'deposit_verified',
          ]; // paymentStatus
        case 'awaiting_driver_verification':
          return const ['awaiting_driver_verification'];
        case 'confirmed':
          return const ['confirmed', 'accepted'];
        case 'running':
          return const ['running', 'active'];
        case 'completed':
          return const ['completed', 'finished'];
        case 'cancelled':
          return const [
            'cancelled',
            'cancelled_by_passenger',
            'cancelled_by_driver',
          ];
        case 'rejected':
          return const ['rejected', 'payment_not_received'];
        case 'refunded':
          return const ['refunded'];
        default:
          return uiStatus;
      }
    }

    final realStatus = getFirestoreStatus(status);
    final streamAsync = ref.watch(
      opsStreamProvider(
        OpsCollectionParams(
          'bookings',
          defaultStatus: realStatus,
          statusField: usePaymentStatus ? 'paymentStatus' : 'status',
          sortLocally: false,
        ),
      ),
    );

    return streamAsync.when(
      data: (bookingMaps) {
        if (bookingMaps.isEmpty) {
          return Center(
            child: Text(
              'لا توجد حجوزات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return _buildDataTable(context, ref, bookingMaps);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookingMaps.length,
              itemBuilder: (context, index) {
                final rawMap = bookingMaps[index];
                if (!rawMap.containsKey('id')) {
                  return const SizedBox.shrink();
                }
                final booking = Booking.fromJson(rawMap);
                return _buildBookingCard(context, ref, booking);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'خطأ في تحميل الحجوزات',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> bookingMaps,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text(
                'رقم الحجز',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الراكب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'رقم الرحلة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'السعر',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الحالة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'حالة الدفع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'إجراءات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: bookingMaps.map((rawMap) {
            final b = Booking.fromJson(rawMap);
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    b.bookingNumber.isNotEmpty
                        ? b.bookingNumber
                        : (b.id.length > 6 ? b.id.substring(0, 6) : b.id),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    b.name.isNotEmpty ? b.name : b.passengerId.substring(0, 5),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    b.tripId.length > 6 ? b.tripId.substring(0, 6) : b.tripId,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    '${b.price} ر.س',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.green,
                    ),
                  ),
                ),
                DataCell(_buildBadge(b.status)),
                DataCell(
                  Text(
                    b.paymentStatus == 'paid' ? 'مدفوع' : 'غير مدفوع',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: b.paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'عرض التفاصيل',
                        onPressed: () => _openDetails(context, b),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) {
    final bookingIdShort = booking.bookingNumber.isNotEmpty
        ? booking.bookingNumber
        : (booking.id.length > 6 ? booking.id.substring(0, 6) : booking.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'حجز #$bookingIdShort',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildBadge(booking.status),
              ],
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                booking.name.isNotEmpty
                    ? booking.name
                    : 'راكب ${booking.passengerId.substring(0, 5)}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'الرحلة: ${booking.departureCity} ➔ ${booking.arrivalCity}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
              trailing: Text(
                '${booking.price} ر.س',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.event_seat, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'مقاعد: ${booking.seatNumbers.join(", ")}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.payment, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.paymentStatus == 'paid' ? 'مدفوع' : 'غير مدفوع',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _openDetails(context, booking),
                  child: const Text(
                    'التفاصيل',
                    style: TextStyle(
                      color: AdminTheme.primary,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (booking.status == 'pending' ||
                    booking.status == 'awaiting_payment' ||
                    booking.status == 'payment_verification') ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        _confirmReject(context, ref, booking.id, 'rejected'),
                    child: const Text(
                      'رفض',
                      style: TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        _confirmAccept(context, ref, booking.id, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Booking booking) {
    context.push(
      '/admin/operations/bookings/details/${booking.id}',
      extra: booking,
    );
  }

  Future<void> _confirmAccept(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    String newStatus,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحجز', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من تأكيد هذا الحجز بالنيابة عن السائق؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('نعم، تأكيد'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref
            .read(tripRepositoryProvider)
            .updateBookingStatus(bookingId, newStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تأكيد الحجز بنجاح',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmReject(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    String newStatus,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الحجز', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من إلغاء/رفض هذا الحجز؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، أرفض الحجز'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(tripRepositoryProvider).cancelBooking(bookingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إلغاء الحجز بنجاح',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBadge(String status) {
    if (status == 'refunded') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'مسترد',
          style: TextStyle(
            color: Colors.orange,
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    final ui = BookingStatusUI.fromStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ui.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ui.label,
        style: TextStyle(
          color: ui.foregroundColor,
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
