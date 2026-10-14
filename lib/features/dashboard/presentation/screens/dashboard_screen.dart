import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/passenger_home_providers.dart';
import '../../../../core/providers/shared_trip_provider.dart';
import '../../../../core/providers/system_config_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../trips/domain/models/trip.dart';
import '../widgets/dashboard_section_header.dart';
import '../widgets/passenger_home_header.dart';
import '../widgets/passenger_search_card.dart';
import '../widgets/passenger_quick_actions.dart';
import '../widgets/passenger_upcoming_booking_card.dart';
import '../widgets/passenger_offer_card.dart';
import '../widgets/suggested_trip_card.dart';
import '../widgets/suggested_trip_card_skeleton.dart';
import '../../../passenger/presentation/providers/passenger_providers.dart';
import '../providers/passenger_navigation_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0B132B) : const Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: const Color(0xFFF5A623),
        backgroundColor: isDark ? const Color(0xFF141F30) : Colors.white,
        onRefresh: () async {
          // Refresh data streams without wiping user search filter
          ref.invalidate(sharedTripsProvider);
          ref.invalidate(dashboardSuggestedTripsProvider);
          ref.invalidate(dashboardUpcomingBookingsProvider);
          ref.invalidate(dashboardOffersProvider);
          ref.invalidate(notificationsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Premium Navy Header
            const PassengerHomeHeader(),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 2. Smart Journey Search Card
                  const PassengerSearchCard(),
                  const SizedBox(height: 20),

                  // 3. Upcoming Booking (Rendered ONLY when valid booking exists)
                  _buildUpcomingBookingSection(),

                  // 4. Quick Services
                  const PassengerQuickActions(),
                  const SizedBox(height: 24),

                  // 5. Saved Places Shortcuts (Rendered if user has saved places)
                  _buildSavedPlacesShortcuts(isDark),

                  // 6. Offers (Rendered ONLY when real active offers exist & feature flag enabled)
                  _buildOffersSection(isDark),

                  // 7. Suggested Trips Section
                  _buildSuggestedTripsSection(isDark),

                  // 8. Bottom spacing for floating navigation bar + safe area
                  SizedBox(height: 110 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookingSection() {
    final upcomingBookingsAsync = ref.watch(dashboardUpcomingBookingsProvider);

    return upcomingBookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return const SizedBox.shrink();
        }
        final nearestBooking = bookings.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardSectionHeader(title: 'رحلتك القادمة'),
            const SizedBox(height: 12),
            PassengerUpcomingBookingCard(booking: nearestBooking),
            const SizedBox(height: 22),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSavedPlacesShortcuts(bool isDark) {
    final profileAsync = ref.watch(passengerProfileProvider);
    return profileAsync.maybeWhen(
      data: (profile) {
        if (profile == null || profile.favoritePlaces.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardSectionHeader(
              title: 'الأماكن المحفوظة',
              actionText: 'إدارة',
              onActionTap: () => context.push('/favorites'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: profile.favoritePlaces.length,
                itemBuilder: (context, index) {
                  final place = profile.favoritePlaces[index];
                  final name = place['name']?.toString() ?? 'مكان';
                  return Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {
                        // Switch to Search tab to begin search
                        ref.read(passengerTabIndexProvider.notifier).state = 1;
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141F30)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(
                                    0xFF0B1F3A,
                                  ).withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 16,
                              color: Color(0xFFF5A623),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
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
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildOffersSection(bool isDark) {
    final flags = ref.watch(featureFlagsProvider).value ?? {};
    final isOffersEnabled = flags['promotions_coupons'] != false;
    if (!isOffersEnabled) return const SizedBox.shrink();

    final offersAsync = ref.watch(dashboardOffersProvider);

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardSectionHeader(
              title: 'عروض لك',
              actionText: 'عرض الكل',
              onActionTap: () => context.push('/offers'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  return PassengerOfferCard(offer: offers[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestedTripsSection(bool isDark) {
    final suggestedTripsAsync = ref.watch(dashboardSuggestedTripsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'رحلات مقترحة',
          actionText: 'عرض الكل',
          onActionTap: () => context.push('/search-results'),
        ),
        const SizedBox(height: 12),
        suggestedTripsAsync.when(
          data: (trips) {
            if (trips.isEmpty) {
              return _buildEmptyTripsState(isDark);
            }
            return _SuggestedTripsCarousel(trips: trips, isDark: isDark);
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const SuggestedTripCardSkeleton(),
          ),
          error: (err, stack) => _buildErrorTripsState(isDark),
        ),
      ],
    );
  }

  Widget _buildEmptyTripsState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF0B1F3A).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5A623).withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.route_rounded,
              size: 28,
              color: Color(0xFFF5A623),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد رحلات مناسبة حالياً',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جرّب تغيير وجهتك أو البحث في وقت لاحق',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => context.push('/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B1F3A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              'ابحث عن رحلة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5A623),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTripsState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 36),
            const SizedBox(height: 8),
            Text(
              'تعذر تحميل الرحلات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0B1F3A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'أعد المحاولة بعد قليل',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => ref.invalidate(dashboardSuggestedTripsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedTripsCarousel extends StatefulWidget {
  final List<Trip> trips;
  final bool isDark;

  const _SuggestedTripsCarousel({required this.trips, required this.isDark});

  @override
  State<_SuggestedTripsCarousel> createState() =>
      _SuggestedTripsCarouselState();
}

class _SuggestedTripsCarouselState extends State<_SuggestedTripsCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  double _viewportFraction = 0.88;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    double newFraction;
    if (screenWidth >= 900) {
      newFraction = 0.36;
    } else if (screenWidth >= 600) {
      newFraction = 0.60;
    } else {
      newFraction = 0.88;
    }

    if (_viewportFraction != newFraction || !(_pageController.hasClients)) {
      _viewportFraction = newFraction;
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: _currentPage,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 290,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.trips.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: SuggestedTripCard(trip: widget.trips[index]),
              );
            },
          ),
        ),
        if (widget.trips.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.trips.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isActive ? 20 : 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFF5A623)
                      : (widget.isDark
                            ? Colors.white24
                            : Colors.black.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
