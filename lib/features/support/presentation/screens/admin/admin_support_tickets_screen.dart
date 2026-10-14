import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../providers/admin_support_providers.dart';
import '../../providers/support_providers.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../../../common/widgets/app_empty_widget.dart';

class AdminSupportTicketsScreen extends ConsumerStatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  ConsumerState<AdminSupportTicketsScreen> createState() =>
      _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState
    extends ConsumerState<AdminSupportTicketsScreen> {
  String _selectedStatus = '';
  String _selectedPriority = '';

  void _showTicketDetailsDialog(BuildContext context, dynamic ticket) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ticket.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم التذكرة: ${ticket.ticketId}'),
              const SizedBox(height: 8),
              Text('الوصف: ${ticket.description}'),
              const SizedBox(height: 16),
              const Text('تغيير الحالة:'),
              DropdownButton<String>(
                value: ticket.status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('قيد المعالجة'),
                  ),
                  DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
                  DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(adminSupportRepositoryProvider)
                        .updateTicketStatus(ticket.ticketId, val);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('تغيير الأولوية:'),
              DropdownButton<String>(
                value: ticket.priority,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                  DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
                  DropdownMenuItem(value: 'high', child: Text('عالية')),
                  DropdownMenuItem(value: 'urgent', child: Text('عاجلة جداً')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(adminSupportRepositoryProvider)
                        .updateTicketPriority(ticket.ticketId, val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final repo = ref.read(
                  supportChatRepositoryProvider(ticket.userType),
                );
                final conv = await repo.createConversationForTicket(
                  ticket.userId,
                  ticket.ticketId,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  // using go_router to navigate
                  GoRouter.of(context).push(
                    '/admin/operations/support/chat/${conv.conversationId}',
                    extra: conv,
                  );
                }
              },
              child: const Text(
                'فتح محادثة',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(
      adminTicketsProvider((
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        priority: _selectedPriority.isEmpty ? null : _selectedPriority,
        userType: null,
        reporterType: null,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التذاكر'),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus.isEmpty ? null : _selectedStatus,
            hint: const Text('الحالة'),
            items: const [
              DropdownMenuItem(value: '', child: Text('الكل')),
              DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
              DropdownMenuItem(
                value: 'in_progress',
                child: Text('قيد المعالجة'),
              ),
              DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
              DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val ?? ''),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedPriority.isEmpty ? null : _selectedPriority,
            hint: const Text('الأولوية'),
            items: const [
              DropdownMenuItem(value: '', child: Text('الكل')),
              DropdownMenuItem(value: 'low', child: Text('منخفضة')),
              DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
              DropdownMenuItem(value: 'high', child: Text('عالية')),
              DropdownMenuItem(value: 'urgent', child: Text('عاجلة جداً')),
            ],
            onChanged: (val) => setState(() => _selectedPriority = val ?? ''),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const AppEmptyWidget(
              message: 'لا توجد تذاكر',
              icon: Icons.receipt_long,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final t = tickets[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt)),
                  title: Text(t.title),
                  subtitle: Text(
                    'رقم: ${t.ticketId.substring(0, 8)} | الحالة: ${t.status}',
                  ),
                  trailing: Text(DateFormat('yyyy-MM-dd').format(t.createdAt)),
                  onTap: () => _showTicketDetailsDialog(context, t),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(
            adminTicketsProvider((
              status: _selectedStatus.isEmpty ? null : _selectedStatus,
              priority: _selectedPriority.isEmpty ? null : _selectedPriority,
              userType: null,
              reporterType: null,
            )),
          ),
        ),
      ),
    );
  }
}
