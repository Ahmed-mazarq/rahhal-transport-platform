import 'package:flutter/material.dart';

class CompanyNotificationsScreen extends StatelessWidget {
  const CompanyNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'تحديد الكل كمقروء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.blue),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNotificationGroup('إشعارات الرحلات والحجوزات', [
              _buildNotificationItem(
                'حجز جديد',
                'تم حجز 4 مقاعد في الرحلة TRP-1002.',
                Icons.event_seat,
                Colors.green,
              ),
              _buildNotificationItem(
                'إلغاء حجز',
                'قام الراكب سالم بإلغاء حجزه.',
                Icons.cancel,
                Colors.red,
              ),
            ]),
            const SizedBox(height: 16),
            _buildNotificationGroup('تنبيهات الأسطول', [
              _buildNotificationItem(
                'موعد صيانة',
                'المركبة KSA-1234 بحاجة لفحص دوري غداً.',
                Icons.build,
                Colors.orange,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildNotificationItem(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ),
        trailing: const Icon(
          Icons.circle,
          size: 10,
          color: Colors.blue,
        ), // Unread indicator
      ),
    );
  }
}
