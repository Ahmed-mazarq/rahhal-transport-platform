import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/driver_profile_resolver_provider.dart';
import '../../../driver/presentation/widgets/driver_avatar.dart';

/// Displays strictly public driver information to passengers.
/// Protects all private documents, national IDs, licenses, emergency contacts,
/// and banking accounts.
class PassengerDriverPublicProfileSheet extends ConsumerWidget {
  final String driverId;
  final String? fallbackName;
  final String? fallbackAvatar;
  final double fallbackRating;

  const PassengerDriverPublicProfileSheet({
    super.key,
    required this.driverId,
    this.fallbackName,
    this.fallbackAvatar,
    this.fallbackRating = 0.0,
  });

  static Future<void> show({
    required BuildContext context,
    required String driverId,
    String? fallbackName,
    String? fallbackAvatar,
    double fallbackRating = 0.0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassengerDriverPublicProfileSheet(
        driverId: driverId,
        fallbackName: fallbackName,
        fallbackAvatar: fallbackAvatar,
        fallbackRating: fallbackRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final driverAsync = ref.watch(driverProfileResolverProvider(driverId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2E42) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: driverAsync.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
              ),
            ),
          ),
          error: (_, _) => _buildProfileContent(
            context,
            name: fallbackName ?? 'كابتن معتمد',
            avatar: fallbackAvatar ?? '',
            rating: fallbackRating,
            completedTrips: 0,
            isVerified: false,
            vehicleSummary: 'مركبة مسجلة في رحال',
            bio: '',
            isDark: isDark,
          ),
          data: (profile) {
            final name = profile?.fullName.isNotEmpty == true
                ? profile!.fullName
                : (fallbackName ?? 'كابتن معتمد');

            final avatar = profile?.profileImage.isNotEmpty == true
                ? profile!.profileImage
                : (fallbackAvatar ?? '');

            final rating = (profile?.rating != null && profile!.rating > 0)
                ? profile.rating
                : fallbackRating;

            final completedTrips = profile?.completedTrips ?? 0;

            final isVerified = profile?.status.toLowerCase() == 'approved' ||
                profile?.verificationStatus.toLowerCase() == 'verified';

            final vehicleMake = profile?.vehicleManufacturer ?? '';
            final vehicleModel = profile?.vehicleModel ?? '';
            final vehicleYear = profile?.vehicleYear ?? '';

            final vehicleSummary = vehicleMake.isNotEmpty
                ? '$vehicleMake $vehicleModel $vehicleYear'.trim()
                : 'مركبة مرخصة ومفحوصة';

            return _buildProfileContent(
              context,
              name: name,
              avatar: avatar,
              rating: rating,
              completedTrips: completedTrips,
              isVerified: isVerified,
              vehicleSummary: vehicleSummary,
              bio: profile?.bio ?? '',
              isDark: isDark,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context, {
    required String name,
    required String avatar,
    required double rating,
    required int completedTrips,
    required bool isVerified,
    required String vehicleSummary,
    required String bio,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sheet Drag Handle
        Container(
          width: 44,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // Avatar & Name Card
        Row(
          children: [
            DriverAvatar(
              imageUrl: avatar,
              radius: 34,
              cacheKey: avatar.isNotEmpty ? avatar : 'driver_${driverId}_avatar',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0B1F3A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVerified ? 'كابتن معتمد من إدارة رحال' : 'كابتن في رحال',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Service Metrics Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF152238)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Rating Metric
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF5A623),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : 'جديد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0B1F3A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'تقييم الركاب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFE5E7EB),
              ),

              // Completed Trips Metric
              Column(
                children: [
                  Text(
                    '$completedTrips',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0B1F3A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'رحلة مكتملة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFE5E7EB),
              ),

              // Safety Verification
              Column(
                children: [
                  Icon(
                    isVerified
                        ? Icons.security_rounded
                        : Icons.shield_outlined,
                    color: isVerified
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF5A623),
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVerified ? 'أوراق موثقة' : 'قيد المراجعة',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Public Vehicle Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF152238)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F3A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF0B1F3A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات المركبة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      vehicleSummary,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0B1F3A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF152238)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              bio,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Close CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B1F3A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'إغلاق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
