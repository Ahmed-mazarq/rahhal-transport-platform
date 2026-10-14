import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real enterprise system, audit logs should be severely paginated.
    // Here we assume the repository streams the latest 200 items.
    final streamAsync = ref.watch(
      systemStreamProvider(SystemCollectionParams('audit_logs')),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'سجل المراجعة (Audit Logs)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black87),
            tooltip: 'تصدير السجل',
            onPressed: () {},
          ),
        ],
      ),
      body: streamAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد سجلات حالية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 800) {
                return _buildDataTable(context, logs);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) =>
                    _buildLogCard(context, logs[index]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    List<Map<String, dynamic>> logs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(
                label: Text(
                  'الوقت',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'المسؤول',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'الإجراء',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'الوحدة المستهدفة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'عنوان IP',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'تفاصيل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: logs.map((log) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      log['createdAt']?.toString().substring(0, 16) ?? '-',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      log['adminName'] ?? 'مسؤول',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(_buildActionBadge(log['action'] ?? 'unknown')),
                  DataCell(
                    Text(
                      log['targetModule'] ?? '-',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  DataCell(
                    Text(
                      log['ipAddress'] ?? '-',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {},
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> log) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              log['adminName'] ?? 'مسؤول',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildActionBadge(log['action'] ?? 'unknown'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'الوحدة: ${log['targetModule'] ?? '-'}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            Text(
              'التاريخ: ${log['createdAt']?.toString().substring(0, 16) ?? '-'}',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    Color color;
    String label;
    switch (action) {
      case 'create':
        color = Colors.green;
        label = 'إنشاء';
        break;
      case 'update':
        color = Colors.orange;
        label = 'تحديث';
        break;
      case 'delete':
        color = Colors.red;
        label = 'حذف';
        break;
      case 'login':
        color = Colors.blue;
        label = 'تسجيل دخول';
        break;
      case 'export':
        color = Colors.purple;
        label = 'تصدير';
        break;
      default:
        color = Colors.grey;
        label = action;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
