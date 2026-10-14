import 'package:flutter/material.dart';

class CompanyReportsScreen extends StatelessWidget {
  const CompanyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التقارير والاستخراج',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'استخراج التقارير بصيغة PDF أو Excel للحسابات والإدارة.',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _buildReportCard(
              'تقرير الرحلات (Trips Report)',
              'سجل الرحلات وتفاصيلها للفترة المحددة',
              Icons.route,
            ),
            _buildReportCard(
              'تقرير الحجوزات (Bookings Report)',
              'حالة الحجوزات وإحصائيات الركاب',
              Icons.book_online,
            ),
            _buildReportCard(
              'تقرير السائقين (Drivers Report)',
              'أداء السائقين وساعات العمل',
              Icons.person,
            ),
            _buildReportCard(
              'تقرير الأسطول (Fleet Report)',
              'حالة المركبات واستخدامها',
              Icons.directions_car,
            ),
            _buildReportCard(
              'تقرير الصيانة (Maintenance Report)',
              'سجل الصيانة وتكاليفها',
              Icons.build,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(
                    0xFF0B1F3A,
                  ).withValues(alpha: 0.1),
                  child: Icon(icon, color: const Color(0xFF0B1F3A)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  label: const Text(
                    'PDF',
                    style: TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  label: const Text(
                    'Excel',
                    style: TextStyle(color: Colors.green, fontFamily: 'Cairo'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, color: Colors.blue),
                  label: const Text(
                    'طباعة',
                    style: TextStyle(color: Colors.blue, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
