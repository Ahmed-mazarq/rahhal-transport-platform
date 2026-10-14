import 'package:flutter/material.dart';

class CompanyBookingDetailsScreen extends StatelessWidget {
  const CompanyBookingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تفاصيل الحجز BKG-9921',
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
            _buildInfoCard('معلومات الراكب', Icons.person, [
              _buildRow('الاسم', 'سالم عبدالله'),
              _buildRow('رقم الهاتف', '+966 50 123 4567'),
              _buildRow('عدد التذاكر', '1'),
              _buildRow('المقاعد', 'رقم 12'),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('معلومات الرحلة', Icons.directions_bus, [
              _buildRow('الرحلة', 'TRP-1002 (الرياض - جدة)'),
              _buildRow('تاريخ السفر', '20 أكتوبر 2023 - 09:00 ص'),
              _buildRow('نقطة الركوب', 'محطة الرياض الرئيسية'),
              _buildRow('نقطة النزول', 'محطة جدة المركزية'),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('حالة الدفع', Icons.payment, [
              _buildRow('المبلغ الإجمالي', '150 ريال'),
              _buildRow('طريقة الدفع', 'البطاقة الائتمانية'),
              _buildRow('الحالة', 'مدفوع بالكامل', valueColor: Colors.green),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(
              'حالة الحضور (Attendance)',
              Icons.check_circle_outline,
              [
                _buildRow(
                  'الحالة الحالية',
                  'لم يتم التحضير بعد',
                  valueColor: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message, color: Colors.green),
                label: const Text(
                  'مراسلة',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cancel),
                label: const Text(
                  'إلغاء الحجز',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0B1F3A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
