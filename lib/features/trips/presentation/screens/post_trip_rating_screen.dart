import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/shared_trip_provider.dart';
import '../../../../core/widgets/rahhal_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/passenger_home_providers.dart';
import '../../domain/models/trip.dart';
import 'my_bookings_screen.dart';
import '../utils/trip_location_display.dart';

class PostTripRatingScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? bookingId;
  final String? driverId;

  const PostTripRatingScreen({
    super.key,
    required this.tripId,
    this.bookingId,
    this.driverId,
  });

  @override
  ConsumerState<PostTripRatingScreen> createState() =>
      _PostTripRatingScreenState();
}

class _PostTripRatingScreenState extends ConsumerState<PostTripRatingScreen> {
  int _driverRating = 0;
  int _vehicleRating = 0;
  int _comfortRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Trip? _trip;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final trip = await tripRepo.getTrip(widget.tripId);
      if (mounted) {
        setState(() {
          _trip = trip;
        });
      }
    } catch (_) {
      // Gracefully ignored, fallback UI used
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_driverRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تقييم الكابتن (نجمة واحدة على الأقل)',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final currentUid = authState is Authenticated
          ? authState.user.uid
          : FirebaseAuth.instance.currentUser?.uid;

      if (currentUid == null) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      final tripRepo = ref.read(tripRepositoryProvider);
      final driverId = widget.driverId ?? _trip?.driverId ?? '';

      if (driverId.isEmpty) {
        throw Exception('بيانات السائق غير متوفرة');
      }

      final categories = <String, dynamic>{
        'driverRating': _driverRating,
        'vehicleRating': _vehicleRating > 0 ? _vehicleRating : _driverRating,
        'comfortRating': _comfortRating > 0 ? _comfortRating : _driverRating,
      };

      await tripRepo.addTripReview(
        tripId: widget.tripId,
        driverId: driverId,
        passengerId: currentUid,
        bookingId: widget.bookingId,
        rating: _driverRating.toDouble(),
        comment: _commentController.text.trim(),
        reviewCategories: categories,
      );

      // Invalidate relevant providers to refresh UI state immediately
      ref.invalidate(passengerAllBookingsProvider);
      ref.invalidate(sharedTripsProvider);
      ref.invalidate(dashboardSuggestedTripsProvider);
      ref.invalidate(dashboardUpcomingBookingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'شكراً لتقييمك! تم تسجيل رأيك ومشاركته بنجاح.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Color(0xFF0B1F3A),
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/my-bookings');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tripRoute = _trip != null
        ? '${TripLocationDisplay.formatOrigin(_trip!)} ⇄ ${TripLocationDisplay.formatDestination(_trip!)}'
        : 'الرحلة';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF8F9FA),
        appBar: const RahhalAppBar(
          titleText: 'تقييم الرحلة',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFF0B1F3A),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'الحمد لله على السلامة!',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'كيف كانت تجربتك في $tripRoute؟',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Driver Rating
              _buildRatingSection(
                isDark,
                title: 'تقييم الكابتن',
                subtitle: 'الالتزام بالمواعيد والتعامل',
                rating: _driverRating,
                onRatingChanged: (val) => setState(() => _driverRating = val),
              ),
              const SizedBox(height: 16),

              // Vehicle Rating
              _buildRatingSection(
                isDark,
                title: 'نظافة وحالة المركبة',
                subtitle: 'المكيف، الترتيب، والراحة العامة',
                rating: _vehicleRating,
                onRatingChanged: (val) => setState(() => _vehicleRating = val),
              ),
              const SizedBox(height: 16),

              // Comfort Rating
              _buildRatingSection(
                isDark,
                title: 'راحة المقاعد والخدمة',
                subtitle: 'مستوى القيادة والأمان على الطريق',
                rating: _comfortRating,
                onRatingChanged: (val) => setState(() => _comfortRating = val),
              ),
              const SizedBox(height: 24),

              // Comment Field
              TextField(
                controller: _commentController,
                maxLines: 4,
                style: const TextStyle(fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'شاركنا تفاصيل أكثر عن تجربتك (اختياري)',
                  hintStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'إرسال التقييم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting ? null : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/my-bookings');
                  }
                },
                child: const Text(
                  'تخطي',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    bool isDark, {
    required String title,
    required String subtitle,
    required int rating,
    required Function(int) onRatingChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isFilled = index < rating;
              return IconButton(
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFF5A623) : Colors.grey[400],
                  size: 34,
                ),
                onPressed: () => onRatingChanged(index + 1),
              );
            }),
          ),
        ],
      ),
    );
  }
}
