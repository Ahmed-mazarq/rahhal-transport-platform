import 'package:flutter/material.dart';

class CompanyRolesScreen extends StatelessWidget {
  const CompanyRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الأدوار والصلاحيات (RBAC)',
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
            _buildRoleCard(
              context,
              'المالك (Owner)',
              'صلاحيات كاملة للتحكم بالنظام',
              true,
              Colors.purple,
            ),
            _buildRoleCard(
              context,
              'مدير العمليات',
              'التحكم بالرحلات والأسطول',
              false,
              Colors.blue,
            ),
            _buildRoleCard(
              context,
              'موظف الحجوزات',
              'إدارة الحجوزات والركاب فقط',
              false,
              Colors.green,
            ),
            _buildRoleCard(
              context,
              'المحاسب',
              'الاطلاع على التقارير المالية والمدفوعات',
              false,
              Colors.orange,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text(
            'دور مخصص',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0B1F3A),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String name,
    String desc,
    bool isDefault,
    Color color,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: color),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'افتراضي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {},
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility),
                  label: const Text(
                    'عرض الصلاحيات',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(fontFamily: 'Cairo'),
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
