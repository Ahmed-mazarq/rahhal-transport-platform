import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../notifications/domain/models/notification.dart' as model;
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../core/theme/admin_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationManagerScreen extends ConsumerStatefulWidget {
  const AdminNotificationManagerScreen({super.key});

  @override
  ConsumerState<AdminNotificationManagerScreen> createState() =>
      _AdminNotificationManagerScreenState();
}

class _AdminNotificationManagerScreenState
    extends ConsumerState<AdminNotificationManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
          title: const Text(
            'إدارة الإشعارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),
          backgroundColor: AdminTheme.topBar,
          elevation: 0,
          iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
          bottom: const TabBar(
            indicatorColor: AdminTheme.secondary,
            labelColor: AdminTheme.secondary,
            unselectedLabelColor: AdminTheme.textMuted,
            labelStyle: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: 'إرسال إشعار', icon: Icon(Icons.send_outlined)),
              Tab(text: 'المسودات', icon: Icon(Icons.drafts_outlined)),
              Tab(text: 'المجدولة', icon: Icon(Icons.schedule_outlined)),
              Tab(text: 'سجل الإرسال', icon: Icon(Icons.history_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CreateNotificationTab(),
            _NotificationsListTab(status: 'draft'),
            _NotificationsListTab(status: 'scheduled'),
            _NotificationsListTab(status: 'sent'),
          ],
        ),
      ),
    );
  }
}

class _CreateNotificationTab extends ConsumerStatefulWidget {
  const _CreateNotificationTab();

  @override
  ConsumerState<_CreateNotificationTab> createState() =>
      _CreateNotificationTabState();
}

class _CreateNotificationTabState
    extends ConsumerState<_CreateNotificationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _userIdController = TextEditingController();

  String _targetRole = 'all';
  String _category = 'system';
  String _priority = 'normal';
  bool _isProcessing = false;

  Future<void> _submit(String status) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final notification = model.Notification(
        id: const Uuid().v4(),
        userId: _targetRole == 'specific_user'
            ? _userIdController.text.trim()
            : '',
        title: _titleController.text,
        body: _bodyController.text,
        createdAt: DateTime.now(),
        category: _category,
        targetRole: _targetRole,
        priority: _priority,
        status: status,
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'system',
        sentAt: status == 'sent' ? DateTime.now() : null,
      );

      final repo = ref.read(notificationRepositoryProvider);

      if (status == 'draft') {
        await repo.saveDraft(notification);
      } else {
        await repo.sendBroadcastNotification(notification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'draft'
                  ? 'تم حفظ المسودة بنجاح'
                  : 'تم إرسال الإشعار بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AdminTheme.success,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AdminTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              color: AdminTheme.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AdminTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل الإشعار',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'عنوان الإشعار',
                          prefixIcon: Icon(
                            Icons.title,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _bodyController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'محتوى الإشعار',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(
                              Icons.notes,
                              color: AdminTheme.textSecondary,
                            ),
                          ),
                        ),
                        maxLines: 4,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _targetRole,
                              decoration: const InputDecoration(
                                labelText: 'الفئة المستهدفة',
                                prefixIcon: Icon(
                                  Icons.group,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('الكل (ركاب، سائقين، شركات)'),
                                ),
                                DropdownMenuItem(
                                  value: 'passenger',
                                  child: Text('الركاب فقط'),
                                ),
                                DropdownMenuItem(
                                  value: 'driver',
                                  child: Text('السائقين فقط'),
                                ),
                                DropdownMenuItem(
                                  value: 'company',
                                  child: Text('الشركات فقط'),
                                ),
                                DropdownMenuItem(
                                  value: 'specific_user',
                                  child: Text('مستخدم محدد (عبر UID)'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _targetRole = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'نوع الإشعار',
                                prefixIcon: Icon(
                                  Icons.category,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'general',
                                  child: Text('عام'),
                                ),
                                DropdownMenuItem(
                                  value: 'system',
                                  child: Text('تحديث نظام'),
                                ),
                                DropdownMenuItem(
                                  value: 'promotion',
                                  child: Text('عرض ترويجي'),
                                ),
                                DropdownMenuItem(
                                  value: 'security',
                                  child: Text('تنبيه أمني'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _category = val!),
                            ),
                          ),
                        ],
                      ),
                      if (_targetRole == 'specific_user') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'معرف المستخدم (UID)',
                            prefixIcon: Icon(
                              Icons.person,
                              color: AdminTheme.textSecondary,
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'الأولوية',
                          prefixIcon: Icon(
                            Icons.low_priority,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('عادية'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('عالية (تجاوز الإعدادات)'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _priority = val!),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _submit('draft'),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('حفظ كمسودة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminTheme.textPrimary,
                              side: const BorderSide(color: AdminTheme.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _submit('sent'),
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('إرسال الآن'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          if (MediaQuery.of(context).size.width > 900)
            Expanded(flex: 1, child: _buildPreview()),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'معاينة الإشعار',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AdminTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 320,
          height: 600,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AdminTheme.border, width: 8),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'رَحّال - Rahhal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                              Text(
                                'الآن',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AdminTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _titleController.text.isEmpty
                                ? 'عنوان الإشعار'
                                : _titleController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bodyController.text.isEmpty
                                ? 'هنا سيظهر محتوى الإشعار الذي ستقوم بكتابته.'
                                : _bodyController.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsListTab extends ConsumerWidget {
  final String status;
  const _NotificationsListTab({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(adminNotificationsProvider(status));

    return stream.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد بيانات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AdminTheme.textMuted,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Card(
              color: AdminTheme.card,
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AdminTheme.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: AdminTheme.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.notifications,
                    color: AdminTheme.primary,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge(notif.targetRole, Colors.blue),
                        const SizedBox(width: 8),
                        _buildBadge(notif.category, Colors.purple),
                        if (status == 'sent') ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: AdminTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${notif.readCount} قراءة',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AdminTheme.textMuted,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: status == 'draft'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: AdminTheme.secondary,
                            ),
                            onPressed: () async {
                              final repo = ref.read(
                                notificationRepositoryProvider,
                              );
                              await repo.updateNotification(
                                notif.copyWith(
                                  status: 'sent',
                                  sentAt: DateTime.now(),
                                ),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'تم الإرسال',
                                      style: TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    backgroundColor: AdminTheme.success,
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AdminTheme.danger,
                            ),
                            onPressed: () async {
                              final repo = ref.read(
                                notificationRepositoryProvider,
                              );
                              await repo.deleteNotification(notif.id);
                            },
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          'خطأ: $e',
          style: const TextStyle(color: AdminTheme.danger, fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
