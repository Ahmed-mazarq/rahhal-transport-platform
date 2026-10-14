import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/rtl_format.dart';
import '../../../../core/widgets/company_info_card.dart';
import '../../../../core/widgets/driver_info_card.dart';
import '../widgets/vehicle_seat_map.dart';
import '../../../common/models/company_model.dart';
import '../../../common/models/driver_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/passenger_search_provider.dart';
import 'passenger_driver_public_profile_sheet.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  Trip? _trip;
  bool _isLoading = false;
  final Set<String> _selectedSeats = {};
  bool _seatSelectionConfirmed = false;
  bool _isConfirmingSeat = false;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
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

  void _onSeatTapped(String seatNum, Map<String, Booking> currentBookings) {
    final authState = ref.read(authProvider);
    final isDriver =
        authState is Authenticated &&
        _trip != null &&
        authState.user.uid == _trip!.driverId;

    if (isDriver) {
      _handleDriverSeatTap(seatNum, currentBookings);
      return;
    }

    final searchState = ref.read(passengerSearchFilterProvider);
    final requiredSeats = searchState.passengerCount;

    setState(() {
      if (_selectedSeats.contains(seatNum)) {
        _selectedSeats.remove(seatNum);
      } else {
        if (_selectedSeats.length >= requiredSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لقد طلبت $requiredSeats مقاعد فقط',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedSeats.add(seatNum);
      }
      _seatSelectionConfirmed = false;
    });
  }

  void _handleDriverSeatTap(
    String seatNum,
    Map<String, Booking> currentBookings,
  ) {
    final booking = currentBookings[seatNum];

    if (booking != null) {
      if (booking.bookingType == 'driver_manual') {
        _showReleaseManualBookingDialog(booking.id, seatNum);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'هذا المقعد محجوز من قبل راكب.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } else {
      _showCreateManualBookingDialog(seatNum);
    }
  }

  void _showReleaseManualBookingDialog(String bookingId, String seatNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تحرير المقعد',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل تريد إزالة الحجز اليدوي عن المقعد $seatNum؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(tripRepositoryProvider);
                await repo.releaseManualDriverBooking(bookingId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحرير المقعد بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            child: const Text(
              'تأكيد',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateManualBookingDialog(String seatNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حجز مقعد يدوياً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل تريد حجز المقعد $seatNum كحجز خاص بك؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(tripRepositoryProvider);
                final authState = ref.read(authProvider);
                if (authState is! Authenticated) return;

                if (_trip == null) return;
                final booking = Booking(
                  id: 'mb_${DateTime.now().millisecondsSinceEpoch}',
                  tripId: widget.tripId,
                  passengerId: authState.user.uid,
                  driverId: authState.user.uid,
                  seatCount: 1,
                  status: 'confirmed',
                  bookingTime: DateTime.now(),
                  seatNumber: seatNum,
                  seatNumbers: [seatNum],
                  bookingType: 'driver_manual',
                  travelDate: _trip!.departureTime,
                );

                await repo.createManualDriverBooking(booking);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حجز المقعد بنجاح')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSelectedSeats() async {
    if (_selectedSeats.isEmpty) return;

    setState(() => _isConfirmingSeat = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tripId', isEqualTo: widget.tripId)
          .where(
            'status',
            whereIn: ['pending_payment', 'payment_verification', 'confirmed'],
          )
          .get();

      final currentReservedSeats = <String>{};
      for (var doc in querySnapshot.docs) {
        final b = Booking.fromJson(doc.data());
        currentReservedSeats.addAll(b.seatNumbers);
      }

      final newlyBooked = _selectedSeats.intersection(currentReservedSeats);

      if (!mounted) return;

      if (newlyBooked.isNotEmpty) {
        setState(() {
          _selectedSeats.removeAll(newlyBooked);
          _seatSelectionConfirmed = false;
          _isConfirmingSeat = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'عذرًا، تم حجز هذا المقعد للتو.',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _seatSelectionConfirmed = true;
          _isConfirmingSeat = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedSeats.length > 1
                  ? '✓ تم تأكيد المقاعد بنجاح'
                  : '✓ تم تأكيد المقعد بنجاح',
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirmingSeat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل التحقق من توفر المقاعد: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToBookingSummary() {
    final searchState = ref.read(passengerSearchFilterProvider);
    final requiredSeats = searchState.passengerCount;

    if (_selectedSeats.length != requiredSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تحديد $requiredSeats مقاعد للمتابعة',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_seatSelectionConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تأكيد المقاعد أولاً قبل المتابعة للدفع',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      context.push('/login');
      return;
    }

    context.push(
      '/booking-summary/${widget.tripId}',
      extra: _selectedSeats.toList()
        ..sort(
          (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading || _trip == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'تفاصيل الرحلة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final trip = _trip!;
    final authState = ref.watch(authProvider);
    final isDriver =
        authState is Authenticated && authState.user.uid == trip.driverId;

    final bool canProceedToPayment =
        _selectedSeats.isNotEmpty && _seatSelectionConfirmed;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.map, size: 100, color: Colors.grey),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${trip.departureProvince.isNotEmpty ? '${trip.departureCountry} • ${trip.departureProvince}' : trip.departureCity} ⇄ ${trip.arrivalProvince.isNotEmpty ? '${trip.arrivalCountry} • ${trip.arrivalProvince}' : trip.arrivalCity}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          RtlFormat.formatPrice(trip.price),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.green,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Timeline & Stops
                  _buildSectionTitle('محطات التوقف', isDark),
                  const SizedBox(height: 16),
                  _buildStopsSection(trip, isDark),
                  const SizedBox(height: 24),

                  // Trip Features
                  _buildSectionTitle('مزايا وقواعد الرحلة', isDark),
                  const SizedBox(height: 16),
                  _buildFeaturesSection(trip, isDark),
                  const SizedBox(height: 24),

                  // Provider Info
                  _buildSectionTitle('مزود الخدمة', isDark),
                  const SizedBox(height: 16),
                  if (trip.isCompany)
                    CompanyInfoCard(
                      company: CompanyModel(
                        id: trip.driverId,
                        ownerId: trip.driverId,
                        name: trip.name,
                        commercialRegister: '',
                        walletBalance: 0,
                        status: 'approved',
                        companyPhone: '',
                        managerName: '',
                        managerPhone: '',
                        country: '',
                        mainCity: '',
                        businessType: '',
                      ),
                      onTap: () {},
                    )
                  else
                    DriverInfoCard(
                      driver: DriverModel(
                        id: trip.driverId,
                        userId: trip.driverId,
                        totalTrips: 0,
                        isVerified: false,
                        licenseNumber: '',
                        vehicleId: '',
                        rating: trip.driverRating,
                        driverType: 'independent',
                        nameOrCode: '',
                      ),
                      onTap: () {
                        PassengerDriverPublicProfileSheet.show(
                          context: context,
                          driverId: trip.driverId,
                          fallbackName: trip.driverName,
                          fallbackAvatar: trip.driverAvatar,
                          fallbackRating: trip.driverRating,
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Seat Map
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('اختر مقعدك', isDark),
                      Text(
                        '${trip.remainingSeats} مقاعد شاغرة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('tripId', isEqualTo: widget.tripId)
                        .where(
                          'status',
                          whereIn: [
                            'pending_payment',
                            'payment_verification',
                            'confirmed',
                          ],
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      final reservedSeatNumbers = <String>{};
                      final currentBookings = <String, Booking>{};
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final b = Booking.fromJson(data..['id'] = doc.id);
                          reservedSeatNumbers.addAll(b.seatNumbers);
                          for (var num in b.seatNumbers) {
                            currentBookings[num] = b;
                          }
                        }
                      }

                      return VehicleSeatMap(
                        trip: trip,
                        reservedSeatNumbers: reservedSeatNumbers,
                        selectedSeatNumbers: _selectedSeats,
                        isConfirmed: _seatSelectionConfirmed,
                        onSeatSelected: (seatNum) =>
                            _onSeatTapped(seatNum, currentBookings),
                        isDriverViewer: isDriver,
                      );
                    },
                  ),
                  if (_selectedSeats.isNotEmpty && !isDriver) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _seatSelectionConfirmed
                            ? Colors.green.withValues(alpha: 0.08)
                            : Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _seatSelectionConfirmed
                              ? Colors.green
                              : Colors.orange,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المقاعد المختارة: ${(_selectedSeats.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0))).join(', ')}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (_seatSelectionConfirmed)
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'مؤكد',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _seatSelectionConfirmed
                                    ? Colors.green
                                    : const Color(0xFFF5A623),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isConfirmingSeat
                                  ? null
                                  : _confirmSelectedSeats,
                              icon: _isConfirmingSeat
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _seatSelectionConfirmed
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      size: 20,
                                    ),
                              label: Text(
                                _seatSelectionConfirmed
                                    ? (_selectedSeats.length > 1
                                          ? '✓ تم تأكيد المقاعد'
                                          : '✓ تم تأكيد المقعد')
                                    : (_selectedSeats.length > 1
                                          ? 'تأكيد المقاعد'
                                          : 'تأكيد المقعد'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجمالي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    RtlFormat.formatPrice(
                      trip.price *
                          (_selectedSeats.isEmpty ? 1 : _selectedSeats.length),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canProceedToPayment
                      ? const Color(0xFF0B1F3A)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: canProceedToPayment ? _goToBookingSummary : null,
                child: const Text(
                  'المتابعة للدفع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildStopsSection(Trip trip, bool isDark) {
    if (trip.stops.isEmpty) {
      return Text(
        'لا توجد محطات توقف في هذه الرحلة',
        style: TextStyle(
          fontFamily: 'Cairo',
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: trip.stops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          final isLast = index == trip.stops.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B1F3A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (stop.pickupAllowed)
                              _buildStopBadge(
                                'صعود مسموح',
                                Colors.green,
                                isDark,
                              ),
                            if (stop.dropoffAllowed)
                              _buildStopBadge(
                                'نزول مسموح',
                                Colors.blue,
                                isDark,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStopBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? color.lighten(0.2) : color,
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(Trip trip, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (trip.hasAc) _buildFeatureChip(Icons.ac_unit, 'مكيف', true, isDark),
        if (trip.hasWifi)
          _buildFeatureChip(Icons.wifi, 'واي فاي', true, isDark),
        if (trip.hasLuggageSpace)
          _buildFeatureChip(Icons.luggage, 'مساحة أمتعة', true, isDark),
        if (trip.allowSmoking)
          _buildFeatureChip(Icons.smoking_rooms, 'التدخين مسموح', true, isDark)
        else
          _buildFeatureChip(
            Icons.smoke_free,
            'التدخين غير مسموح',
            false,
            isDark,
          ),
      ],
    );
  }

  Widget _buildFeatureChip(
    IconData icon,
    String label,
    bool isPositive,
    bool isDark,
  ) {
    final bgColor = isPositive
        ? const Color(0xFF0B1F3A).withOpacity(0.1)
        : Colors.red.withOpacity(0.1);
    final iconColor = isPositive
        ? const Color(0xFFD4AF37) // Gold
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : (isPositive
                    ? const Color(0xFF0B1F3A).withOpacity(0.2)
                    : Colors.red.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
