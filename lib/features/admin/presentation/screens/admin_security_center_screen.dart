import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/admin_system_provider.dart';
import '../../../common/utils/date_parser.dart';

class AdminSecurityCenterScreen extends ConsumerWidget {
  const AdminSecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(
      systemStreamProvider(SystemCollectionParams('security_events')),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'مركز الأمان (Security Center)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: streamAsync.when(
        data: (events) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThreatDashboard(),
                const SizedBox(height: 24),
                const Text(
                  'أحدث التنبيهات الأمنية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (events.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'لا توجد أحداث أمنية مسجلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) =>
                        _buildSecurityCard(context, events[index]),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
        ),
      ),
    );
  }

  Widget _buildThreatDashboard() {
    return Consumer(
      builder: (context, ref, child) {
        // Fetch locked users stream
        final lockedUsersAsync = ref.watch(
          systemStreamProvider(
            SystemCollectionParams(
              'users',
              typeFilter: 'locked',
              typeField: 'status',
            ),
          ),
        );
        final lockedCount = lockedUsersAsync.valueOrNull?.length ?? 0;

        // Count failed logins from events
        final eventsAsync = ref.watch(
          systemStreamProvider(SystemCollectionParams('security_events')),
        );
        final events = eventsAsync.valueOrNull ?? [];
        final failedLoginsCount = events
            .where((e) => e['type'] == 'failed_login')
            .length;
        final blockedIpsCount = events
            .where((e) => e['type'] == 'blocked_ip')
            .length;

        // Simple fraud indicator logic
        final fraudLevel = (failedLoginsCount > 10 || lockedCount > 5)
            ? 'مرتفع'
            : (failedLoginsCount > 5 ? 'متوسط' : 'منخفض');
        final fraudColor = (failedLoginsCount > 10 || lockedCount > 5)
            ? Colors.red
            : (failedLoginsCount > 5 ? Colors.orange : Colors.green);

        return LayoutBuilder(
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
              childAspectRatio: 2.0,
              children: [
                _buildStatCard(
                  'محاولات دخول فاشلة',
                  failedLoginsCount.toString(),
                  Icons.login,
                  Colors.orange,
                ),
                _buildStatCard(
                  'حسابات مقفلة',
                  lockedCount.toString(),
                  Icons.lock,
                  Colors.red,
                ),
                _buildStatCard(
                  'IPs محظورة',
                  blockedIpsCount.toString(),
                  Icons.block,
                  Colors.redAccent,
                ),
                _buildStatCard(
                  'مؤشر الاحتيال',
                  fraudLevel,
                  Icons.verified_user,
                  fraudColor,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context, Map<String, dynamic> event) {
    final createdAt = DateParser.parse(event['createdAt']);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 2),
      ),
      color: Colors.red.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.warning, color: Colors.white),
        ),
        title: Text(
          event['title']?.toString() ?? 'تنبيه أمني',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              event['description']?.toString() ?? '',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateParser.formatDateTime(createdAt),
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () async {
            try {
              if (event['userId'] != null) {
                await FirebaseFunctions.instance
                    .httpsCallable('revokeUserSessions')
                    .call({'uid': event['userId']});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم حظر الجلسات بنجاح',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'خطأ: $e',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('حظر فوري', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ),
    );
  }
}
