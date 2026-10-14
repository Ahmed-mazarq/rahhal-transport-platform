import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'driver_dashboard_screen.dart';
import 'driver_trips_screen.dart';
import 'driver_bookings_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import 'driver_profile_screen.dart';
import '../providers/driver_navigation_provider.dart';
import '../providers/driver_badges_provider.dart';
import '../utils/driver_tokens.dart';

class DriverLayoutScreen extends ConsumerStatefulWidget {
  const DriverLayoutScreen({super.key});

  @override
  ConsumerState<DriverLayoutScreen> createState() => _DriverLayoutScreenState();
}

class _DriverLayoutScreenState extends ConsumerState<DriverLayoutScreen> {
  late final List<Widget?> _builtScreens;

  @override
  void initState() {
    super.initState();
    _builtScreens = List<Widget?>.filled(5, null);
    // Initial login must build ONLY DriverDashboardScreen
    _builtScreens[0] = const DriverDashboardScreen();
  }

  Widget _createScreen(int index) {
    switch (index) {
      case 0:
        return const DriverDashboardScreen();
      case 1:
        return const DriverTripsScreen();
      case 2:
        return const DriverBookingsScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const DriverProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(driverTabIndexProvider);
    final safeIndex = (currentIndex >= 0 && currentIndex < 5)
        ? currentIndex
        : 0;
    _builtScreens[safeIndex] ??= _createScreen(safeIndex);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unreadNotificationsCount =
        ref.watch(driverUnreadNotificationsCountProvider).value ?? 0;
    final actionRequiredBookingsCount =
        ref.watch(driverActionRequiredBookingsCountProvider).value ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: List.generate(
            5,
            (i) => _builtScreens[i] ?? const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? DriverTokens.cardDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: DriverTokens.accentGold.withValues(alpha: 0.18),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark
                            ? DriverTokens.accentGold
                            : DriverTokens.primaryNavy)
                      : (isDark ? Colors.white60 : Colors.black54),
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 24,
                  color: isSelected
                      ? (isDark
                            ? DriverTokens.accentGold
                            : DriverTokens.primaryNavy)
                      : (isDark ? Colors.white60 : Colors.black54),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index != currentIndex) {
                  HapticFeedback.selectionClick();
                  ref.read(driverTabIndexProvider.notifier).state = index;
                }
              },
              backgroundColor: isDark ? DriverTokens.cardDark : Colors.white,
              elevation: 0,
              height: 70,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'الرئيسية',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car_rounded),
                  label: 'رحلاتي',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: actionRequiredBookingsCount > 0,
                    label: Text('$actionRequiredBookingsCount'),
                    backgroundColor: DriverTokens.warning,
                    child: const Icon(Icons.calendar_today_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: actionRequiredBookingsCount > 0,
                    label: Text('$actionRequiredBookingsCount'),
                    backgroundColor: DriverTokens.warning,
                    child: const Icon(Icons.calendar_today_rounded),
                  ),
                  label: 'الحجوزات',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: unreadNotificationsCount > 0,
                    label: Text('$unreadNotificationsCount'),
                    backgroundColor: DriverTokens.error,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unreadNotificationsCount > 0,
                    label: Text('$unreadNotificationsCount'),
                    backgroundColor: DriverTokens.error,
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  label: 'الإشعارات',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
