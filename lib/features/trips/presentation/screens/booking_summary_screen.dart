import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/providers/repository_providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/trip.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  final String tripId;
  final List<String> selectedSeats;

  const BookingSummaryScreen({
    super.key,
    required this.tripId,
    this.selectedSeats = const [],
  });

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  Trip? _trip;
  bool _isLoading = false;
  bool _policyAccepted = false;
  late int _selectedSeatsCount;

  @override
  void initState() {
    super.initState();
    _selectedSeatsCount = widget.selectedSeats.isNotEmpty
        ? widget.selectedSeats.length
        : 1;
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    setState(() => _isLoading = true);
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final details = await tripRepo.getTrip(widget.tripId);
      if (mounted) {
        setState(() => _trip = details);
      }
    } catch (e) {
      // Ignored
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _proceedToPayment() async {
    if (!_policyAccepted || _trip == null) return;

    setState(() => _isLoading = true);
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final authState = ref.read(authProvider);
      final passengerId = (authState is Authenticated)
          ? authState.user.id
          : 'unknown';
      final passengerName = (authState is Authenticated)
          ? authState.user.fullName
          : 'مسافر';

      final totalAmount = _trip!.price * _selectedSeatsCount;
      const double depositAmount = 100.0;
      final remainingAmount = totalAmount - depositAmount;

      final booking = Booking(
        id: const Uuid().v4(),
        tripId: widget.tripId,
        passengerId: passengerId,
        name: passengerName, // Uses the real passenger name
        driverId: _trip!.driverId,
        seatCount: _selectedSeatsCount.toDouble(),
        seatNumber: widget.selectedSeats.join(','),
        seatNumbers: widget.selectedSeats,
        price: totalAmount,
        currency: _trip!.currency,
        depositAmount: depositAmount,
        remainingAmount: remainingAmount,
        status: 'pending_payment',
        paymentStatus: 'not_submitted',
        bookingTime: DateTime.now(),
        travelDate: _trip!.departureTime,
        departureCity: _trip!.departureCity,
        arrivalCity: _trip!.arrivalCity,
        driverName: _trip!.isCompany ? _trip!.name : _trip!.driverName,
        paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
      );

      // Create Booking Request via transaction to safely reserve seats
      await tripRepo.createBookingRequest(booking);

      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to the payment screen to show driver's payment methods
        context.push('/booking-payment/${booking.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Exception:')
                  ? e.toString().split('Exception: ').last
                  : 'تعذر إنشاء طلب الحجز.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading && _trip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_trip == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'الرحلة غير موجودة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    final trip = _trip!;
    final total = trip.price * _selectedSeatsCount;
    const deposit = 100.0;
    final remaining = total - deposit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الحجز', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ),
            children: [
              _buildSectionCard(
                isDark,
                title: 'معلومات الرحلة',
                child: Column(
                  children: [
                    _buildRow(
                      'الرحلة',
                      '${trip.departureCity} ← ${trip.arrivalCity}',
                    ),
                    const Divider(),
                    _buildRow(
                      'الشركة/السائق',
                      trip.isCompany ? trip.name : trip.driverName,
                    ),
                    const Divider(),
                    _buildRow(
                      'تاريخ السفر',
                      DateFormat(
                        'dd MMMM yyyy',
                        'ar',
                      ).format(trip.departureTime),
                    ),
                    const Divider(),
                    _buildRow(
                      'وقت المغادرة',
                      DateFormat('hh:mm a', 'ar').format(trip.departureTime),
                    ),
                    const Divider(),
                    _buildRow('المقعد', widget.selectedSeats.join(', ')),
                    const Divider(),
                    _buildRow('عدد المسافرين', '$_selectedSeatsCount'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                isDark,
                title: 'التفاصيل المالية',
                child: Column(
                  children: [
                    _buildRow(
                      'إجمالي الرحلة',
                      '$total ${trip.currency}',
                      isBold: true,
                    ),
                    const Divider(),
                    _buildRow(
                      'مبلغ تأكيد الحجز',
                      '$deposit ${trip.currency}',
                      isBold: true,
                      color: const Color(0xFFF5A623),
                    ),
                    const Divider(),
                    _buildRow(
                      'المتبقي عند السفر',
                      '$remaining ${trip.currency}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Booking Policy
              Text(
                'سياسة الحجز',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2235)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'لتأكيد حجزك، يجب تحويل مبلغ 100 ريال مباشرة إلى وسيلة الدفع المسجلة لدى السائق. لن يصبح الحجز مؤكدًا حتى يتحقق السائق من وصول المبلغ.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Checkbox
              CheckboxListTile(
                value: _policyAccepted,
                onChanged: (value) {
                  setState(() => _policyAccepted = value ?? false);
                },
                title: const Text(
                  'أوافق على سياسة الحجز والإلغاء',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF0B1F3A),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _policyAccepted && !_isLoading
                ? _proceedToPayment
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFF0B1F3A),
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'متابعة للدفع',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    bool isDark, {
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
