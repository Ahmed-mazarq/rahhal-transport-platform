import 'package:flutter/material.dart';

class CompanyDriverAssignmentScreen extends StatelessWidget {
  const CompanyDriverAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'محرك تعيين السائقين',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'اختر السائق ثم اربطه بالمركبة والرحلة لضمان عدم حدوث تعارض في المواعيد.',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Driver Selection
            _buildSelectionBox(
              context,
              '1. اختيار السائق',
              'محمد عبدالله',
              'متاح للعمل - لا توجد رحلات جارية',
              Icons.person,
            ),
            const SizedBox(height: 16),
            const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
            const SizedBox(height: 16),

            // Vehicle Selection
            _buildSelectionBox(
              context,
              '2. اختيار المركبة',
              'مرسيدس بنز Tourismo',
              'KSA 1234 - متاح وغير مرتبط برحلة',
              Icons.directions_car,
            ),
            const SizedBox(height: 16),
            const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
            const SizedBox(height: 16),

            // Trip Selection
            _buildSelectionBox(
              context,
              '3. ربط برحلة (اختياري)',
              'رحلة TRP-1002 (الرياض - جدة)',
              'تبدأ غداً الساعة 09:00 صباحاً',
              Icons.route,
            ),

            const SizedBox(height: 40),

            // Validation & Submission
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'التعيين صالح! لا يوجد تعارض في أوقات الرحلة أو حالة الصيانة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1F3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حفظ واعتماد التعيين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBox(
    BuildContext context,
    String title,
    String subtitle,
    String desc,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0B1F3A).withValues(alpha: 0.1),
              child: Icon(icon, color: const Color(0xFF0B1F3A)),
            ),
            title: Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              desc,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.green,
              ),
            ),
            trailing: TextButton(
              onPressed: () {},
              child: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ),
        ],
      ),
    );
  }
}
