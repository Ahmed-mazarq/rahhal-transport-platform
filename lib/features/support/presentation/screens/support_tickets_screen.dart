import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/support_providers.dart';

class SupportTicketsScreen extends ConsumerWidget {
  final String userType;
  const SupportTicketsScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider(userType));

    return Scaffold(
      appBar: AppBar(title: const Text('تذاكري'), centerTitle: true),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد تذاكر حالية.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final basePath = userType == 'passenger'
                          ? '/support'
                          : '/$userType-support';
                      context.push('$basePath/create-ticket');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء تذكرة جديدة'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () async {
                    String? finalConversationId = ticket.conversationId;

                    if (context.mounted) {
                      final queryParams = <String>[];
                      if (finalConversationId != null) {
                        queryParams.add('conversationId=$finalConversationId');
                      }
                      queryParams.add('ticketId=${ticket.ticketId}');
                      final queryString = queryParams.join('&');
                      final basePath = userType == 'passenger'
                          ? '/support'
                          : '/$userType-support';
                      context.push('$basePath/chat?$queryString');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ticket.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildStatusBadge(ticket.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تاريخ الإنشاء: ${_formatDate(ticket.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'رقم: #${ticket.ticketId.substring(0, 6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('حدث خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final basePath = userType == 'passenger'
              ? '/support'
              : '/$userType-support';
          context.push('$basePath/create-ticket');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'open':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'مفتوحة';
        break;
      case 'in_progress':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        label = 'قيد المعالجة';
        break;
      case 'resolved':
      case 'closed':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'مغلقة';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
