import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import '../../../trips/presentation/screens/search_screen.dart';
import '../../../trips/presentation/screens/my_bookings_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../passenger/presentation/screens/passenger_profile_screen.dart';
import '../providers/passenger_navigation_provider.dart';

class PassengerLayoutScreen extends ConsumerStatefulWidget {
  const PassengerLayoutScreen({super.key});

  @override
  ConsumerState<PassengerLayoutScreen> createState() =>
      _PassengerLayoutScreenState();
}

class _PassengerLayoutScreenState extends ConsumerState<PassengerLayoutScreen> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    SearchScreen(),
    MyBookingsScreen(),
    NotificationsScreen(),
    PassengerProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (ref.read(passengerTabIndexProvider) == index) return;
    HapticFeedback.selectionClick();
    ref.read(passengerTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentIndex = ref.watch(passengerTabIndexProvider);

    const goldAccent = Color(0xFFF5A623);
    const navyPrimary = Color(0xFF0B1F3A);

    final bgColor = isDark ? const Color(0xFF0B132B) : const Color(0xFFF7F8FA);
    final navBgColor = isDark ? const Color(0xFF141F30) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: IndexedStack(index: currentIndex, children: _screens),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: navBgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : navyPrimary.withValues(alpha: 0.06),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : navyPrimary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: isDark
                      ? goldAccent.withValues(alpha: 0.18)
                      : navyPrimary.withValues(alpha: 0.08),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? goldAccent : navyPrimary)
                          : (isDark ? Colors.white60 : Colors.black45),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: isSelected
                          ? (isDark ? goldAccent : navyPrimary)
                          : (isDark ? Colors.white60 : Colors.black45),
                      size: isSelected ? 25 : 23,
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: _onTabTapped,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  height: 64,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'الرئيسية',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.search_rounded),
                      selectedIcon: Icon(Icons.search_rounded),
                      label: 'بحث',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.confirmation_number_outlined),
                      selectedIcon: Icon(Icons.confirmation_number_rounded),
                      label: 'حجوزاتي',
                    ),
                    NavigationDestination(
                      icon: unreadCount > 0
                          ? Badge(
                              label: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: goldAccent,
                              textColor: navyPrimary,
                              child: const Icon(
                                Icons.notifications_none_rounded,
                              ),
                            )
                          : const Icon(Icons.notifications_none_rounded),
                      selectedIcon: unreadCount > 0
                          ? Badge(
                              label: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: goldAccent,
                              textColor: navyPrimary,
                              child: const Icon(Icons.notifications_rounded),
                            )
                          : const Icon(Icons.notifications_rounded),
                      label: 'إشعارات',
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
        ),
      ),
    );
  }
}
