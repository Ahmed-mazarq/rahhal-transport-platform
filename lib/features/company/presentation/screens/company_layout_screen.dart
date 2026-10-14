import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'company_dashboard_screen.dart';
import 'company_trips_screen.dart';
import 'company_fleet_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class CompanyLayoutScreen extends ConsumerStatefulWidget {
  const CompanyLayoutScreen({super.key});

  @override
  ConsumerState<CompanyLayoutScreen> createState() =>
      _CompanyLayoutScreenState();
}

class _CompanyLayoutScreenState extends ConsumerState<CompanyLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CompanyDashboardScreen(), // 🏠 الرئيسية
    CompanyTripsScreen(), // 🚐 الرحلات
    CompanyFleetScreen(), // 👨‍✈️ الأسطول
    NotificationsScreen(), // 🔔 الإشعارات
    SettingsScreen(), // 🏢 الشركة
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            selectedItemColor: const Color(0xFF0B1F3A),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
            ),
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard, color: Color(0xFF0B1F3A)),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.commute_outlined),
                activeIcon: Icon(Icons.commute, color: Color(0xFF0B1F3A)),
                label: 'الرحلات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people, color: Color(0xFF0B1F3A)),
                label: 'الأسطول',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_outlined),
                activeIcon: Icon(Icons.notifications, color: Color(0xFF0B1F3A)),
                label: 'الإشعارات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business, color: Color(0xFF0B1F3A)),
                label: 'الشركة',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
