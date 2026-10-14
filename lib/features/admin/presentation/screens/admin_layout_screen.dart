import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminLayoutScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminLayoutScreen({super.key, required this.navigationShell});

  void _onDestinationSelected(int index, WidgetRef ref, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AdminTheme.theme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 800) {
                  // Desktop / Tablet layout
                  return Row(
                    children: [
                      NavigationRail(
                        backgroundColor: AdminTheme.sidebar,
                        selectedIndex: navigationShell.currentIndex,
                        onDestinationSelected: (index) =>
                            _onDestinationSelected(index, ref, context),
                        labelType: NavigationRailLabelType.all,
                        unselectedIconTheme: const IconThemeData(
                          color: Colors.white70,
                          opacity: 1,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                        ),
                        selectedIconTheme: const IconThemeData(
                          color: Colors.white,
                          opacity: 1,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        indicatorColor: AdminTheme.secondary,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('الرئيسية'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: Text('المستخدمين'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_suggest_outlined),
                            selectedIcon: Icon(Icons.settings_suggest),
                            label: Text('العمليات'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_outlined),
                            selectedIcon: Icon(Icons.analytics),
                            label: Text('التحليلات'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.admin_panel_settings_outlined),
                            selectedIcon: Icon(Icons.admin_panel_settings),
                            label: Text('النظام'),
                          ),
                        ],
                        trailing: Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: IconButton(
                                tooltip: 'تسجيل خروج',
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  ref.read(authProvider.notifier).logout().then(
                                    (_) {
                                      if (context.mounted) {
                                        context.go('/admin-login');
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        thickness: 1,
                        width: 1,
                        color: AdminTheme.border,
                      ),
                      Expanded(child: navigationShell),
                    ],
                  );
                } else {
                  // Mobile Layout
                  return Column(children: [Expanded(child: navigationShell)]);
                }
              },
            ),
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width < 800
              ? NavigationBar(
                  backgroundColor: AdminTheme.sidebar,
                  indicatorColor: AdminTheme.secondary,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) =>
                      _onDestinationSelected(index, ref, context),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(
                        Icons.dashboard_outlined,
                        color: Colors.white70,
                      ),
                      selectedIcon: Icon(Icons.dashboard, color: Colors.white),
                      label: 'الرئيسية',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline, color: Colors.white70),
                      selectedIcon: Icon(Icons.people, color: Colors.white),
                      label: 'المستخدمين',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.settings_suggest_outlined,
                        color: Colors.white70,
                      ),
                      selectedIcon: Icon(
                        Icons.settings_suggest,
                        color: Colors.white,
                      ),
                      label: 'العمليات',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.analytics_outlined,
                        color: Colors.white70,
                      ),
                      selectedIcon: Icon(Icons.analytics, color: Colors.white),
                      label: 'التحليلات',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white70,
                      ),
                      selectedIcon: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                      ),
                      label: 'النظام',
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}
