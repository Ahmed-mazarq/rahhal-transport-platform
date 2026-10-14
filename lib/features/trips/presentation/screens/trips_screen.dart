import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/passenger_search_provider.dart';
import 'package:rahal/core/providers/shared_trip_provider.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/features/trips/domain/services/trip_search_service.dart';
import 'package:rahal/features/dashboard/presentation/providers/passenger_navigation_provider.dart';
import '../utils/trip_location_display.dart';
import 'package:rahal/core/utils/currency_formatter.dart';
import 'package:rahal/core/theme/app_theme.dart';

enum TripSortOption {
  soonestDeparture, // الأقرب موعداً
  lowestPrice, // الأقل سعراً
  highestRating, // الأعلى تقييماً
  mostSeatsAvailable, // الأكثر مقاعد متاحة
}

final tripSortOptionProvider = StateProvider<TripSortOption>(
  (ref) => TripSortOption.soonestDeparture,
);

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final searchResults = ref.watch(searchResultsProvider);
    final searchState = ref.watch(passengerSearchFilterProvider);
    final sortOption = ref.watch(tripSortOptionProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'نتائج البحث',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              ref.read(passengerTabIndexProvider.notifier).state = 1;
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Compact Search Summary Card with "تعديل البحث"
          _buildSearchSummaryCard(
            context: context,
            ref: ref,
            searchState: searchState,
            isDark: isDark,
            primaryNavy: primaryNavy,
            accentGold: accentGold,
          ),

          // Main Content
          Expanded(
            child: searchResults.when(
              loading: () => _buildLoadingSkeleton(isDark),
              error: (error, stack) =>
                  _buildErrorState(ref, isDark, primaryNavy),
              data: (searchResult) {
                if (searchResult.matchType == SearchMatchType.empty ||
                    searchResult.trips.isEmpty) {
                  return _buildEmptyState(
                    context,
                    ref,
                    isDark,
                    searchState,
                    primaryNavy,
                  );
                }

                // Apply local sorting without mutating original lists
                final sortedTrips = List<Trip>.from(searchResult.trips);
                switch (sortOption) {
                  case TripSortOption.soonestDeparture:
                    sortedTrips.sort(
                      (a, b) => a.departureTime.compareTo(b.departureTime),
                    );
                    break;
                  case TripSortOption.lowestPrice:
                    sortedTrips.sort((a, b) => a.price.compareTo(b.price));
                    break;
                  case TripSortOption.highestRating:
                    sortedTrips.sort(
                      (a, b) => b.driverRating.compareTo(a.driverRating),
                    );
                    break;
                  case TripSortOption.mostSeatsAvailable:
                    sortedTrips.sort(
                      (a, b) => b.remainingSeats.compareTo(a.remainingSeats),
                    );
                    break;
                }

                return RefreshIndicator(
                  color: accentGold,
                  onRefresh: () async {
                    ref.invalidate(sharedTripsProvider);
                  },
                  child: Column(
                    children: [
                      // Fallback Banner
                      if (searchResult.matchType ==
                          SearchMatchType.countryFallback)
                        _buildFallbackBanner(isDark, searchState),

                      // Sort Bar & Result Count
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${sortedTrips.length} رحلة متاحة',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                            InkWell(
                              onTap: () => _showSortModal(context, ref, isDark),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF252525)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: accentGold,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getSortLabel(sortOption),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Trip List
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 20,
                          ),
                          itemCount: sortedTrips.length,
                          itemBuilder: (context, index) {
                            final trip = sortedTrips[index];
                            return _TripCard(
                              trip: trip,
                              isDark: isDark,
                              primaryNavy: primaryNavy,
                              accentGold: accentGold,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummaryCard({
    required BuildContext context,
    required WidgetRef ref,
    required PassengerSearchState searchState,
    required bool isDark,
    required Color primaryNavy,
    required Color accentGold,
  }) {
    final fromText =
        searchState.departureCity?.nameAr ??
        searchState.departureProvince?.nameAr ??
        searchState.departureCountry?.nameAr ??
        'الكل';
    final toText =
        searchState.arrivalCity?.nameAr ??
        searchState.arrivalProvince?.nameAr ??
        searchState.arrivalCountry?.nameAr ??
        'الكل';

    final dateText = searchState.travelDate != null
        ? DateFormat('d MMM', 'ar').format(searchState.travelDate!)
        : 'أي تاريخ';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fromText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: accentGold,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        toText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateText,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${searchState.passengerCount} مقاعد',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              // Return to Search with filters preserved
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                ref.read(passengerTabIndexProvider.notifier).state = 1;
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('تعديل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryNavy,
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(bool isDark, PassengerSearchState searchState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF5A623).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF5A623),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لم نجد رحلة مطابقة تماماً',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFF5A623),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'نعرض لك رحلات بديلة ضمن نفس الدول (${searchState.departureCountry?.nameAr ?? ''} إلى ${searchState.arrivalCountry?.nameAr ?? ''}).',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    PassengerSearchState searchState,
    Color primaryNavy,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252525)
                    : const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 40,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد رحلات مطابقة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب تغيير الوجهة أو التاريخ أو عدد المقاعد للبحث عن خيارات أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      ref.read(passengerTabIndexProvider.notifier).state = 1;
                    }
                  },
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('تعديل البحث'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, bool isDark, Color primaryNavy) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل الرحلات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تحقق من الاتصال بالإنترنت ثم أعد المحاولة.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.invalidate(sharedTripsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showSortModal(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final current = ref.watch(tripSortOptionProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    'ترتيب الرحلات حسب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...TripSortOption.values.map((opt) {
                  final isSelected = current == opt;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      _getSortLabel(opt),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? AppTheme.secondaryColor : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.secondaryColor,
                          )
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(tripSortOptionProvider.notifier).state = opt;
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSortLabel(TripSortOption opt) {
    switch (opt) {
      case TripSortOption.soonestDeparture:
        return 'الأقرب موعداً';
      case TripSortOption.lowestPrice:
        return 'الأقل سعراً';
      case TripSortOption.highestRating:
        return 'الأعلى تقييماً';
      case TripSortOption.mostSeatsAvailable:
        return 'الأكثر مقاعد متاحة';
    }
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final bool isDark;
  final Color primaryNavy;
  final Color accentGold;

  const _TripCard({
    required this.trip,
    required this.isDark,
    required this.primaryNavy,
    required this.accentGold,
  });

  String _formatCurrency(double price, String currency) {
    return formatCurrencyAmount(price, currency);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm a', 'ar');
    final hasValidRating = trip.driverRating > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/trip-details/${trip.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Driver Avatar + Name + Rating + Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primaryNavy.withValues(alpha: 0.1),
                      backgroundImage: trip.driverAvatar.isNotEmpty
                          ? NetworkImage(trip.driverAvatar)
                          : null,
                      child: trip.driverAvatar.isEmpty
                          ? Icon(Icons.person, color: primaryNavy, size: 22)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  trip.driverName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (trip.tripType == 'company' ||
                                  trip.isCompany) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (hasValidRating) ...[
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trip.driverRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'جديد',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (trip.vehicleType.isNotEmpty) ...[
                                Icon(
                                  Icons.directions_car_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    trip.vehicleType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatCurrency(trip.price, trip.currency),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accentGold,
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Divider(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ),

                // Journey Route
                Row(
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.trip_origin_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        Container(
                          height: 24,
                          width: 2,
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                        ),
                        Icon(
                          Icons.location_on_rounded,
                          color: accentGold,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TripLocationDisplay.formatOrigin(trip),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            TripLocationDisplay.formatDestination(trip),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Departure Time & Available Seats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat_rounded,
                          color: Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.remainingSeats} مقاعد متاحة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(trip.departureTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Amenities Badges (AC, WiFi, VIP, Family, Women)
                if (trip.hasAc ||
                    trip.hasWifi ||
                    trip.isVip ||
                    trip.isFamilyOnly ||
                    trip.isWomenOnly) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (trip.isVip)
                        _buildAmenityChip(
                          'VIP',
                          Icons.star_rounded,
                          Colors.amber,
                          isDark,
                        ),
                      if (trip.hasAc)
                        _buildAmenityChip(
                          'مكيف',
                          Icons.ac_unit_rounded,
                          Colors.cyan,
                          isDark,
                        ),
                      if (trip.hasWifi)
                        _buildAmenityChip(
                          'واي فاي',
                          Icons.wifi_rounded,
                          Colors.blue,
                          isDark,
                        ),
                      if (trip.isFamilyOnly)
                        _buildAmenityChip(
                          'عائلات',
                          Icons.family_restroom_rounded,
                          Colors.purple,
                          isDark,
                        ),
                      if (trip.isWomenOnly)
                        _buildAmenityChip(
                          'نساء فقط',
                          Icons.female_rounded,
                          Colors.pink,
                          isDark,
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/trip-details/${trip.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
