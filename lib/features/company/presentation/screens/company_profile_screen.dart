import 'package:flutter/material.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الملف الشخصي للشركة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () {})],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1560179707-f14e90ef3623?q=80&w=200&auto=format&fit=crop',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'شركة رحال للنقل البري',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),
                  const Text(
                    'عضو منذ 2021 | التقييم: 4.8 ⭐️',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'نشط (موثق)',
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

            const SizedBox(height: 32),

            // Statistics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard('الأسطول', '120 مركبة', Icons.directions_bus),
                _buildStatCard('السائقين', '150 سائق', Icons.person),
                _buildStatCard('الموظفين', '25 موظف', Icons.badge),
                _buildStatCard('الرحلات', '1,200+', Icons.route),
              ],
            ),

            const SizedBox(height: 32),

            // Editable Information
            _buildSectionTitle('المعلومات الأساسية'),
            _buildInfoRow('المدير العام', 'سالم عبدالله'),
            _buildInfoRow('الهاتف الأساسي', '+966 50 123 4567'),
            _buildInfoRow('البريد الإلكتروني', 'contact@rahhal.com'),
            _buildInfoRow('الموقع الإلكتروني', 'www.rahhal.com'),

            const SizedBox(height: 24),
            _buildSectionTitle('العنوان وساعات العمل'),
            _buildInfoRow('الدولة / المدينة', 'السعودية / الرياض'),
            _buildInfoRow('العنوان', 'طريق الملك فهد، حي الملقا'),
            _buildInfoRow('ساعات العمل', '08:00 ص - 05:00 م'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0B1F3A)),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B1F3A),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
