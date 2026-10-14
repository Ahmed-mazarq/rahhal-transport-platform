import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_operations_provider.dart';
import '../../../common/enums/support_status.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'البلاغات والمخالفات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: const Color(0xFF0B1F3A),
          indicatorColor: const Color(0xFF0B1F3A),
          tabs: const [
            Tab(text: 'قيد التحقيق'),
            Tab(text: 'مرفوضة'),
            Tab(text: 'مغلقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsTabView(status: SupportStatus.open.value),
          _ReportsTabView(status: SupportStatus.rejected.value),
          _ReportsTabView(status: SupportStatus.resolved.value),
        ],
      ),
    );
  }
}

class _ReportsTabView extends ConsumerWidget {
  final String status;
  const _ReportsTabView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(
      opsStreamProvider(OpsCollectionParams('reports', defaultStatus: status)),
    );

    return streamAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد بلاغات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) =>
              _buildReportCard(context, reports[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: Border(
        right: BorderSide(
          color: _getSeverityColor(report['severity']),
          width: 4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report['type'] ?? 'بلاغ عام',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  report['createdAt']?.toString().substring(0, 10) ?? '-',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report['description'] ?? 'بدون تفاصيل',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.black87,
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'المبلغ: ${report['reporterName'] ?? '-'}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.warning_amber, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'ضد: ${report['targetName'] ?? '-'}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (status == 'open') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'رفض وإغلاق',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1F3A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'تحقيق واتخاذ إجراء',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }
}
