import 'package:flutter/material.dart';

class CompanyDocumentsScreen extends StatelessWidget {
  const CompanyDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'وثائق الشركة وتراخيص النقل',
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
            _buildDocCard(
              'السجل التجاري',
              'CR-1029384756',
              '2024-12-31',
              'معتمد',
              Colors.green,
            ),
            _buildDocCard(
              'ترخيص الهيئة العامة للنقل',
              'TGA-8847',
              '2023-11-15',
              'قيد المراجعة',
              Colors.orange,
            ),
            _buildDocCard(
              'شهادة التأمين الطبي',
              'INS-5531',
              '2023-01-10',
              'منتهي',
              Colors.red,
            ),
            _buildDocCard(
              'رخصة البلدية',
              'MUN-1122',
              '2025-05-20',
              'معتمد',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(
    String title,
    String number,
    String expiry,
    String status,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الرقم: $number',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'تاريخ الانتهاء: $expiry',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility),
                  label: const Text(
                    'معاينة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text(
                    'تحديث / استبدال',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                if (status == 'منتهي')
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'حذف',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
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
