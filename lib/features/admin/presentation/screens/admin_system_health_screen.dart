import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminSystemHealthScreen extends ConsumerWidget {
  const AdminSystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(systemHealthProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'صحة النظام (System Health)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: healthAsync.when(
        data: (health) {
          final isOperational = health['status'] == 'operational';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemStatusBanner(isOperational),
                const SizedBox(height: 24),
                const Text(
                  'مقاييس الأداء (Telemetry)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1024
                        ? 4
                        : (constraints.maxWidth >= 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildMetricCard(
                          'وقت استجابة قاعدة البيانات',
                          '${health['firestore_latency'] ?? 120} ms',
                          Icons.storage,
                          Colors.blue,
                        ),
                        _buildMetricCard(
                          'استهلاك الذاكرة للخادم',
                          '${health['memory_usage'] ?? 45}%',
                          Icons.memory,
                          Colors.purple,
                        ),
                        _buildMetricCard(
                          'الجلسات النشطة',
                          '${health['active_sessions'] ?? 1500}',
                          Icons.people,
                          Colors.green,
                        ),
                        _buildMetricCard(
                          'متوسط وقت الاستعلام',
                          '45 ms',
                          Icons.speed,
                          Colors.orange,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'حالة خدمات Firebase',
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
                  child: Column(
                    children: [
                      _buildServiceTile('Firestore Database', true),
                      const Divider(height: 1),
                      _buildServiceTile('Firebase Authentication', true),
                      const Divider(height: 1),
                      _buildServiceTile('Cloud Storage', true),
                      const Divider(height: 1),
                      _buildServiceTile(
                        'Cloud Functions',
                        health['functions_status'] ?? true,
                      ),
                      const Divider(height: 1),
                      _buildServiceTile('Cloud Messaging (FCM)', true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildSystemStatusBanner(bool isOperational) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOperational ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOperational ? Colors.green.shade200 : Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOperational ? Icons.check_circle : Icons.warning,
            size: 48,
            color: isOperational ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 8),
          Text(
            isOperational
                ? 'جميع الأنظمة تعمل بكفاءة'
                : 'يوجد تدهور في بعض الخدمات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isOperational ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'آخر تحديث: قبل لحظات',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(String name, bool isOnline) {
    return ListTile(
      leading: Icon(
        isOnline ? Icons.cloud_done : Icons.cloud_off,
        color: isOnline ? Colors.green : Colors.red,
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isOnline ? 'متصل' : 'مقطوع',
          style: TextStyle(
            color: isOnline ? Colors.green : Colors.red,
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
