import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../trips/domain/models/trip.dart';
import '../../../trips/domain/models/seat.dart';
import '../../../../core/providers/repository_providers.dart';
import '../widgets/interactive_seat_map.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';

class DriverTripDetailsScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const DriverTripDetailsScreen({super.key, required this.trip});

  @override
  ConsumerState<DriverTripDetailsScreen> createState() =>
      _DriverTripDetailsScreenState();
}

class _DriverTripDetailsScreenState
    extends ConsumerState<DriverTripDetailsScreen> {
  late Trip _trip;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  void _startTrip() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .updateTripStatus(_trip.id, 'running');
      if (mounted) {
        setState(() {
          _trip = _trip.copyWith(status: 'running');
          _isLoading = false;
        });
        context.push('/driver-live-trip', extra: _trip);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر بدء الرحلة، يرجى المحاولة لاحقاً'),
            backgroundColor: DriverTokens.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _cancelTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء الرحلة'),
          content: const Text(
            'هل أنت متأكد من إلغاء الرحلة؟ سيتم إشعار الركاب المسجلين.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTokens.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .updateTripStatus(_trip.id, 'cancelled');
      if (mounted) {
        setState(() {
          _trip = _trip.copyWith(status: 'cancelled');
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الرحلة بنجاح'),
            backgroundColor: DriverTokens.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إلغاء الرحلة، يرجى المحاولة لاحقاً'),
            backgroundColor: DriverTokens.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  String _translateSeatStatus(Seat seat) {
    switch (seat.status.toLowerCase()) {
      case 'booked':
      case 'reserved':
        return 'محجوز';
      case 'blocked':
        return 'محجوب / غير متاح';
      case 'available':
      default:
        if (seat.isWomenOnly) return 'متاح (مخصص للنساء)';
        if (seat.isVip) return 'متاح (VIP)';
        return 'متاح للحجز';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusUi = DriverTripStatusUi.fromStatus(_trip.status);

    final departureStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
      'ar',
    ).format(_trip.departureTime);
    final arrivalStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
      'ar',
    ).format(_trip.arrivalTime);

    final currencyLabel = _trip.currency.isNotEmpty
        ? _trip.currency.toUpperCase()
        : 'SAR';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : DriverTokens.backgroundLight,
        appBar: AppBar(
          title: Text(
            'تفاصيل الرحلة #${_trip.id.length > 6 ? _trip.id.substring(0, 6) : _trip.id}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: isDark ? DriverTokens.cardDark : Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? DriverTokens.cardDark : Colors.white,
                borderRadius: DriverTokens.borderCard,
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حالة الرحلة',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusUi.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusUi.foregroundColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusUi.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusUi.icon,
                      color: statusUi.foregroundColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route & Timings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? DriverTokens.cardDark : Colors.white,
                borderRadius: DriverTokens.borderCard,
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مسار ومواعيد الرحلة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 18,
                        color: DriverTokens.primaryNavy,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الانطلاق: ${_trip.departureCity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        departureStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      height: 16,
                      child: VerticalDivider(
                        thickness: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: DriverTokens.accentGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الوصول: ${_trip.arrivalCity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        arrivalStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle and Pricing Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? DriverTokens.cardDark : Colors.white,
                borderRadius: DriverTokens.borderCard,
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'المركبة',
                    '${_trip.vehicleBrand} ${_trip.vehicleModel} (${_trip.vehiclePlate})',
                    isDark,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'سعر المقعد',
                    '${_trip.price.toStringAsFixed(0)} $currencyLabel',
                    isDark,
                    isHighlight: true,
                  ),
                  if (_trip.parcelPrice != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      'سعر الطرد',
                      '${_trip.parcelPrice!.toStringAsFixed(0)} $currencyLabel',
                      isDark,
                    ),
                  ],
                  const Divider(),
                  _buildDetailRow(
                    'إجمالي المقاعد',
                    '${_trip.totalSeats} مقاعد (${_trip.remainingSeats} متاح)',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seat Map Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? DriverTokens.cardDark : Colors.white,
                borderRadius: DriverTokens.borderCard,
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'خريطة المقاعد والحجوزات',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InteractiveSeatMap(
                    seats: _trip.seatLayout,
                    onSeatTap: (seat) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'المقعد رقم ${seat.number}: ${_translateSeatStatus(seat)}',
                            textAlign: TextAlign.right,
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stops Section
            if (_trip.stops.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? DriverTokens.cardDark : Colors.white,
                  borderRadius: DriverTokens.borderCard,
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'محطات التوقف',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._trip.stops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stop = entry.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: DriverTokens.primaryNavy.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          stop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          stop.pickupAllowed && stop.dropoffAllowed
                              ? 'صعود ونزول مسموح'
                              : (stop.pickupAllowed
                                    ? 'صعود فقط'
                                    : (stop.dropoffAllowed
                                          ? 'نزول فقط'
                                          : 'محطة مرور')),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions Area
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_trip.status == 'open_for_booking' ||
                  _trip.status == 'published') ...[
                ElevatedButton.icon(
                  onPressed: _startTrip,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('بدء الرحلة الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTokens.accentGold,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _cancelTrip,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: DriverTokens.error,
                  ),
                  label: const Text(
                    'إلغاء الرحلة',
                    style: TextStyle(color: DriverTokens.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    side: const BorderSide(color: DriverTokens.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else if (_trip.status == 'running') ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/driver-live-trip', extra: _trip),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('متابعة الرحلة الحية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTokens.accentGold,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? DriverTokens.success
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
