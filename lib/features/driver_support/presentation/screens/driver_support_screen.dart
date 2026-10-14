import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/driver_support_providers.dart';

class DriverSupportScreen extends ConsumerWidget {
  const DriverSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(driverTicketsProvider);
    final unreadAsync = ref.watch(driverUnreadMessagesCountProvider);

    int openTickets = 0;
    ticketsAsync.whenData((tickets) {
      openTickets = tickets
          .where((t) => t.status != 'closed' && t.status != 'resolved')
          .length;
    });

    int unreadMessages = 0;
    unreadAsync.whenData((count) {
      unreadMessages = count;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز مساعدة السائقين'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.drive_eta, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'كيف يمكننا مساعدتك؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'فريق الدعم متاح دائماً للرد على استفساراتك وحل مشاكلك.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              children: [
                _buildMenuCard(
                  context: context,
                  title: 'المحادثة الفورية',
                  subtitle: 'تحدث مع الدعم',
                  icon: Icons.chat,
                  color: Colors.green,
                  badgeCount: unreadMessages > 0 ? unreadMessages : null,
                  onTap: () => context.push('/driver-support/chat'),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'تذاكري',
                  subtitle: 'متابعة الطلبات',
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                  badgeCount: openTickets > 0 ? openTickets : null,
                  onTap: () => context.push('/driver-support/tickets'),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'إنشاء تذكرة',
                  subtitle: 'طلب مساعدة جديد',
                  icon: Icons.add_circle_outline,
                  color: Colors.teal,
                  onTap: () => context.push('/driver-support/create-ticket'),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'الإبلاغ عن مشكلة',
                  subtitle: 'شكوى أو بلاغ',
                  icon: Icons.report_problem,
                  color: Colors.red,
                  onTap: () => context.push('/driver-support/report'),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'الأسئلة الشائعة',
                  subtitle: 'إجابات سريعة',
                  icon: Icons.help_outline,
                  color: Colors.purple,
                  onTap: () => context.push('/driver-support/faq'),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'تواصل معنا',
                  subtitle: 'معلومات الاتصال',
                  icon: Icons.contact_support,
                  color: Colors.indigo,
                  onTap: () => context.push('/driver-support/contact'),
                ),
                _buildMenuCard(
                  context: context,
                  title: 'بلاغاتي',
                  subtitle: 'متابعة البلاغات',
                  icon: Icons.report,
                  color: Colors.deepOrange,
                  onTap: () => context.push('/driver-support/reports'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
