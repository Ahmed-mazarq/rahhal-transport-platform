import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../providers/admin_support_providers.dart';
import 'package:go_router/go_router.dart';

class AdminSupportConversationsScreen extends StatefulWidget {
  const AdminSupportConversationsScreen({super.key});

  @override
  State<AdminSupportConversationsScreen> createState() =>
      _AdminSupportConversationsScreenState();
}

class _AdminSupportConversationsScreenState
    extends State<AdminSupportConversationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              text: 'طوارئ',
              icon: Icon(Icons.warning, color: Colors.red),
            ),
            Tab(text: 'الركاب', icon: Icon(Icons.person)),
            Tab(text: 'السائقين', icon: Icon(Icons.drive_eta)),
            Tab(text: 'الشركات', icon: Icon(Icons.business)),
            Tab(text: 'مغلقة', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ConversationListTab(
            filter: (
              priority: 'urgent',
              status: 'open',
              userType: null,
              reporterType: null,
            ),
          ),
          _ConversationListTab(
            filter: (
              userType: 'passenger',
              status: 'open',
              priority: null,
              reporterType: null,
            ),
          ),
          _ConversationListTab(
            filter: (
              userType: 'driver',
              status: 'open',
              priority: null,
              reporterType: null,
            ),
          ),
          _ConversationListTab(
            filter: (
              userType: 'company',
              status: 'open',
              priority: null,
              reporterType: null,
            ),
          ),
          _ConversationListTab(
            filter: (
              status: 'closed',
              priority: null,
              userType: null,
              reporterType: null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationListTab extends ConsumerWidget {
  final AdminSupportFilters filter;
  const _ConversationListTab({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(adminConversationsProvider(filter));

    return convsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return const Center(child: Text('لا توجد محادثات'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: conv.userType == 'company'
                      ? Colors.teal
                      : (conv.userType == 'driver'
                            ? Colors.orange
                            : Colors.blue),
                  child: Icon(
                    conv.userType == 'company'
                        ? Icons.business
                        : (conv.userType == 'driver'
                              ? Icons.drive_eta
                              : Icons.person),
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Text('رقم: ${conv.conversationId.substring(0, 8)}...'),
                    if (conv.conversationType == 'ticket')
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'تذكرة',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      )
                    else if (conv.conversationType == 'report')
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'بلاغ',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'دعم',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('النوع: ${conv.userType} - الحالة: ${conv.status}'),
                    Text(
                      'أخر تحديث: ${DateFormat('yyyy-MM-dd HH:mm').format(conv.updatedAt)}',
                    ),
                  ],
                ),
                trailing: conv.priority == 'urgent'
                    ? const Icon(Icons.warning, color: Colors.red)
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  GoRouter.of(context).push(
                    '/admin/operations/support/chat/${conv.conversationId}',
                    extra: conv,
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.refresh(adminConversationsProvider(filter)),
      ),
    );
  }
}
