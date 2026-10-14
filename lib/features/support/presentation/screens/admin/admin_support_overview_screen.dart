import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_support_providers.dart';
import '../../../../common/widgets/app_error_widget.dart';

class AdminSupportOverviewScreen extends ConsumerWidget {
  const AdminSupportOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      body: statsAsync.when(
        data: (stats) {
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 3; // Max 3 per row on wide screens
              double childAspect = 1.6;

              if (constraints.maxWidth < 600) {
                crossAxisCount = 1;
                childAspect = 2.5;
              } else if (constraints.maxWidth < 900) {
                crossAxisCount = 2;
                childAspect = 1.8;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نظرة عامة على الدعم الفني',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspect,
                      children: [
                        _buildStatCard(
                          'محادثات مفتوحة',
                          stats['openConversations'] ?? 0,
                          Icons.chat,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'محادثات جديدة',
                          stats['newConversations'] ?? 0,
                          Icons.new_releases,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'بانتظار الرد',
                          stats['waitingForReply'] ?? 0,
                          Icons.hourglass_empty,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'محادثات الطوارئ',
                          stats['urgentChats'] ?? 0,
                          Icons.warning_amber,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'التذاكر',
                          stats['tickets'] ?? 0,
                          Icons.receipt_long,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'البلاغات',
                          stats['reports'] ?? 0,
                          Icons.report,
                          Colors.deepOrange,
                        ),
                        _buildStatCard(
                          'رسائل غير مقروءة',
                          stats['unreadMessages'] ?? 0,
                          Icons.mark_email_unread,
                          Colors.indigo,
                        ),
                        _buildStatCard(
                          'محادثات مغلقة',
                          stats['closedConversations'] ?? 0,
                          Icons.check_circle,
                          Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Potential charts can be placed here
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(adminDashboardStatsProvider),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
