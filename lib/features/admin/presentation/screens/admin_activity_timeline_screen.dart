import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminActivityTimelineScreen extends ConsumerWidget {
  const AdminActivityTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We reuse the audit_logs stream, but display it chronologically as a timeline feed.
    final streamAsync = ref.watch(
      systemStreamProvider(SystemCollectionParams('audit_logs')),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'المخطط الزمني للأحداث (Timeline)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: streamAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد أحداث جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildTimelineNode(
                context,
                event,
                isLast: index == events.length - 1,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context,
    Map<String, dynamic> event, {
    required bool isLast,
  }) {
    final action = event['action'] ?? 'unknown';
    Color color;
    IconData icon;

    switch (action) {
      case 'create':
        color = Colors.green;
        icon = Icons.add_circle;
        break;
      case 'update':
        color = Colors.orange;
        icon = Icons.edit;
        break;
      case 'delete':
        color = Colors.red;
        icon = Icons.delete;
        break;
      case 'login':
        color = Colors.blue;
        icon = Icons.login;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
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
                            event['adminName'] ?? 'النظام',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            event['createdAt']?.toString().substring(0, 16) ??
                                'الآن',
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
                        'الوحدة المستهدفة: ${event['targetModule'] ?? 'عام'}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.black87,
                        ),
                      ),
                      if (event['details'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          event['details'].toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
