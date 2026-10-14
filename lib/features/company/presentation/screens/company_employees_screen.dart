import 'package:flutter/material.dart';

class CompanyEmployeesScreen extends StatelessWidget {
  const CompanyEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الموظفين (Employees)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.security, color: Colors.blue),
              label: const Text(
                'إدارة الأدوار (RBAC)',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.blue),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4, // Mock count, would be unlimited
          itemBuilder: (context, index) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: const NetworkImage(
                    'https://randomuser.me/api/portraits/men/44.jpg',
                  ),
                  radius: 24,
                ),
                title: const Text(
                  'أحمد خالد محمد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'الدور: مدير العمليات (Operations Manager)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'القسم: الدعم الفني والعمليات',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) {},
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text(
                        'عرض التفاصيل',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'تعديل',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Text(
                        'إيقاف الحساب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'حذف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.person_add),
          label: const Text(
            'إضافة موظف جديد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0B1F3A),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
