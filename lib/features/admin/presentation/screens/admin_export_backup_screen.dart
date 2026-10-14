import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminExportBackupScreen extends ConsumerStatefulWidget {
  const AdminExportBackupScreen({super.key});

  @override
  ConsumerState<AdminExportBackupScreen> createState() =>
      _AdminExportBackupScreenState();
}

class _AdminExportBackupScreenState
    extends ConsumerState<AdminExportBackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'التصدير والنسخ الاحتياطي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: const Color(0xFF0B1F3A),
          indicatorColor: const Color(0xFF0B1F3A),
          tabs: const [
            Tab(text: 'مركز التصدير (Export)'),
            Tab(text: 'النسخ الاحتياطي (Backup)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExportTab(), _buildBackupTab()],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تصدير البيانات التشغيلية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اختر الوحدة والصيغة المناسبة لتحميل البيانات.',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1024
                  ? 3
                  : (constraints.maxWidth >= 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildExportCard('سجل الركاب', Icons.people, [
                    'CSV',
                    'Excel',
                    'PDF',
                  ]),
                  _buildExportCard('سجل السائقين', Icons.drive_eta, [
                    'CSV',
                    'Excel',
                  ]),
                  _buildExportCard('الرحلات المكتملة', Icons.route, [
                    'CSV',
                    'Excel',
                    'PDF',
                  ]),
                  _buildExportCard('سجلات الحجوزات', Icons.book_online, [
                    'CSV',
                    'Excel',
                  ]),
                  _buildExportCard('تذاكر الدعم الفني', Icons.support_agent, [
                    'CSV',
                  ]),
                  _buildExportCard('سجل المراجعة (Audit)', Icons.security, [
                    'CSV',
                    'PDF',
                  ]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(String title, IconData icon, List<String> formats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Icon(icon, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: formats
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('جاري إنشاء ملف $f...')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة النسخ الاحتياطي (Disaster Recovery)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يتطلب النسخ الاحتياطي الكامل تفعيل Firebase Cloud Functions.',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'النسخ الاحتياطي اليدوي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اضغط هنا لطلب نسخة احتياطية كاملة من قاعدة البيانات والإعدادات والمحتوى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم إرسال طلب النسخ الاحتياطي للرابط الخلفي (Backend)',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text(
                      'بدء النسخ الاحتياطي الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1F3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'أرشيف النسخ الاحتياطية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.archive, color: Colors.green),
                  title: Text(
                    'نسخة احتياطية آلية - ${DateTime.now().subtract(Duration(days: index * 7)).toString().substring(0, 10)}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'الحجم: 1.2 GB',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'استعادة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
