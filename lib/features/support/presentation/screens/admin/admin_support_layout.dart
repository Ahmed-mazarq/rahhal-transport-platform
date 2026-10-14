import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import 'admin_support_overview_screen.dart';
import 'admin_support_conversations_screen.dart';
import 'admin_support_tickets_screen.dart';
import 'admin_support_reports_screen.dart';
import 'admin_support_faq_settings_screen.dart';
import 'admin_support_contact_screen.dart';

class AdminSupportLayout extends ConsumerStatefulWidget {
  const AdminSupportLayout({super.key});

  @override
  ConsumerState<AdminSupportLayout> createState() => _AdminSupportLayoutState();
}

class _AdminSupportLayoutState extends ConsumerState<AdminSupportLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminSupportOverviewScreen(),
    const AdminSupportConversationsScreen(),
    const AdminSupportTicketsScreen(),
    const AdminSupportReportsScreen(),
    const AdminSupportFaqSettingsScreen(),
    const AdminSupportContactScreen(),
    const AdminSupportSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final navigationItems = [
      (
        icon: Icons.dashboard_outlined,
        selected: Icons.dashboard,
        label: 'نظرة عامة',
      ),
      (icon: Icons.chat_outlined, selected: Icons.chat, label: 'المحادثات'),
      (
        icon: Icons.receipt_long_outlined,
        selected: Icons.receipt_long,
        label: 'التذاكر',
      ),
      (icon: Icons.report_outlined, selected: Icons.report, label: 'البلاغات'),
      (
        icon: Icons.help_outline,
        selected: Icons.help,
        label: 'الأسئلة الشائعة',
      ),
      (
        icon: Icons.contact_mail_outlined,
        selected: Icons.contact_mail,
        label: 'التواصل',
      ),
      (
        icon: Icons.settings_outlined,
        selected: Icons.settings,
        label: 'الإعدادات',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الدعم الفني'),
        centerTitle: true,
        leading: isDesktop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/admin/dashboard'),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'العودة للوحة التحكم',
              onPressed: () => context.go('/admin/dashboard'),
            ),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: AppTheme.primaryColor),
                    child: Center(
                      child: Text(
                        'إدارة الدعم الفني',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(navigationItems.length, (index) {
                    final item = navigationItems[index];
                    final isSelected = _selectedIndex == index;
                    return ListTile(
                      leading: Icon(
                        isSelected ? item.selected : item.icon,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[800],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  }),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        selectedIconTheme: const IconThemeData(
                          color: AppTheme.primaryColor,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: Colors.grey[600],
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          color: Colors.grey[600],
                        ),
                        destinations: navigationItems
                            .map(
                              (item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.selected),
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}

class AdminSupportSettingsScreen extends StatelessWidget {
  const AdminSupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('إعدادات الدعم', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
