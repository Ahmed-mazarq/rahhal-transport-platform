import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/common/models/user_model.dart';
import 'package:rahal/features/common/models/vehicle_model.dart';
import '../../../trips/domain/models/trip.dart';
import '../../../trips/presentation/utils/trip_location_display.dart';
import '../../../../core/providers/driver_profile_resolver_provider.dart';
import '../../../driver/presentation/widgets/driver_avatar.dart';
import 'suggested_trip_card_skeleton.dart';

class SuggestedTripCard extends ConsumerWidget {
  final Trip trip;
  final UserModel? driver;
  final VehicleModel? vehicle;
  final double rating;
  final int reviewsCount;
  final bool isLoading;

  const SuggestedTripCard({
    super.key,
    required this.trip,
    this.driver,
    this.vehicle,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const SuggestedTripCardSkeleton();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final driverAsync = ref.watch(driverProfileResolverProvider(trip.driverId));
    final resolvedDriver = driverAsync.value;

    final driverName =
        resolvedDriver?.fullName ??
        driver?.fullName ??
        (trip.driverName.isNotEmpty ? trip.driverName : 'سائق معتمد');

    final driverImage = (resolvedDriver?.profileImage.isNotEmpty == true)
        ? resolvedDriver!.profileImage
        : (driver?.profileImage.isNotEmpty == true)
        ? driver!.profileImage
        : trip.driverAvatar;

    final vehicleImage = trip.vehiclePhotoUrl.isNotEmpty
        ? trip.vehiclePhotoUrl
        : (vehicle?.photoUrl.isNotEmpty == true)
        ? vehicle!.photoUrl
        : '';

    final origin = TripLocationDisplay.getOrigin(trip);
    final destination = TripLocationDisplay.getDestination(trip);

    final formattedTime = DateFormat('hh:mm a').format(trip.departureTime);
    final formattedDate = DateFormat('yyyy/MM/dd').format(trip.departureTime);

    // Collect 2-3 meaningful chips
    final chips = <Widget>[];
    if (trip.isVip) {
      chips.add(_buildChip('VIP', const Color(0xFFF5A623), Colors.white));
    }
    if (trip.isFamilyOnly && chips.length < 3) {
      chips.add(_buildChip('عائلي', const Color(0xFF8E44AD), Colors.white));
    }
    if (trip.isWomenOnly && chips.length < 3) {
      chips.add(_buildChip('نساء فقط', const Color(0xFFE91E63), Colors.white));
    }
    if (trip.hasWifi && chips.length < 3) {
      chips.add(_buildChip('Wi-Fi', const Color(0xFF2980B9), Colors.white));
    }
    if (trip.hasAc && chips.length < 3) {
      chips.add(_buildChip('تكييف', const Color(0xFF16A085), Colors.white));
    }

    final cardBg = isDark ? const Color(0xFF141F30) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF0B1F3A).withValues(alpha: 0.06);

    return Semantics(
      button: true,
      label:
          'رحلة من $origin إلى $destination بسعر ${trip.price} ${trip.currency}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/trip-details/${trip.id}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFF0B1F3A).withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle image / header banner
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 105,
                        child: vehicleImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: vehicleImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark
                                      ? const Color(0xFF0B1F3A)
                                      : Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.directions_car_rounded,
                                      color: Colors.grey,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDark
                                      ? const Color(0xFF0B1F3A)
                                      : Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.directions_car_rounded,
                                      color: Colors.grey,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? const Color(0xFF0B1F3A)
                                    : const Color(0xFFEEF2F6),
                                child: const Center(
                                  child: Icon(
                                    Icons.directions_car_rounded,
                                    color: Color(0xFFF5A623),
                                    size: 42,
                                  ),
                                ),
                              ),
                      ),
                      // Gradient overlay for contrast
                      Container(
                        height: 105,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      // Price Badge on top right
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0B1F3A,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF5A623),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${trip.price.toStringAsFixed(0)} ${trip.currency}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Feature Badges on top left
                      if (chips.isNotEmpty)
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: chips,
                          ),
                        ),
                    ],
                  ),
                ),
                // Card Body
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              DriverAvatar(
                                imageUrl: driverImage,
                                radius: 14,
                                cacheKey:
                                    resolvedDriver?.profileImageUpdatedAt !=
                                        null
                                    ? '${driverImage}_${resolvedDriver!.profileImageUpdatedAt}'
                                    : driverImage,
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Text(
                                  driverName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0B1F3A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Builder(
                            builder: (context) {
                              final realRating = (resolvedDriver?.rating != null &&
                                      resolvedDriver!.rating > 0)
                                  ? resolvedDriver.rating
                                  : trip.driverRating;
                              if (realRating > 0) {
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFF5A623),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      realRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'جديد',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Route Origin -> Destination
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              origin,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0B1F3A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFFF5A623),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              destination,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0B1F3A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Date, Time & Remaining Seats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$formattedTime • $formattedDate',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF5A623,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${trip.remainingSeats} مقاعد متبقية',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5A623),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Primary action button: عرض التفاصيل
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/trip-details/${trip.id}');
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFFF5A623)
                                  : const Color(0xFF0B1F3A),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'عرض التفاصيل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF5A623)
                                  : const Color(0xFF0B1F3A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
