import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/admin_support_providers.dart';
import '../../providers/support_providers.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../../../common/widgets/app_empty_widget.dart';
import '../../../domain/models/support_report.dart';

class AdminSupportReportsScreen extends ConsumerStatefulWidget {
  const AdminSupportReportsScreen({super.key});

  @override
  ConsumerState<AdminSupportReportsScreen> createState() =>
      _AdminSupportReportsScreenState();
}

class _AdminSupportReportsScreenState
    extends ConsumerState<AdminSupportReportsScreen> {
  String _selectedStatus = '';

  void _showReportDetailsDialog(BuildContext context, SupportReport report) {
    showDialog(
      context: context,
      builder: (context) {
        return _ReportDetailsDialog(report: report);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(
      adminReportsProvider((
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        priority: null,
        userType: null,
        reporterType: null,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البلاغات'),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus.isEmpty ? null : _selectedStatus,
            hint: const Text('الحالة'),
            items: const [
              DropdownMenuItem(value: '', child: Text('الكل')),
              DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
              DropdownMenuItem(
                value: 'investigating',
                child: Text('قيد التحقيق'),
              ),
              DropdownMenuItem(value: 'resolved', child: Text('محلول')),
              DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val ?? ''),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const AppEmptyWidget(
              message: 'لا توجد بلاغات',
              icon: Icons.report_off,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.report, color: Colors.white),
                  ),
                  title: Text(r.reason),
                  subtitle: Text(
                    'المبلغ: ${r.reporterType} | الحالة: ${r.status}',
                  ),
                  trailing: Text(DateFormat('yyyy-MM-dd').format(r.createdAt)),
                  onTap: () => _showReportDetailsDialog(context, r),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(
            adminReportsProvider((
              status: _selectedStatus.isEmpty ? null : _selectedStatus,
              priority: null,
              userType: null,
              reporterType: null,
            )),
          ),
        ),
      ),
    );
  }
}

class _ReportDetailsDialog extends ConsumerWidget {
  final SupportReport report;
  const _ReportDetailsDialog({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reporterAsync = ref.watch(
      adminUserDetailsProvider((
        userId: report.reporterId,
        userType: report.reporterType,
      )),
    );

    final reportedAsync =
        report.reportedId != null && report.reportedType != null
        ? ref.watch(
            adminUserDetailsProvider((
              userId: report.reportedId!,
              userType: report.reportedType!,
            )),
          )
        : null;

    return AlertDialog(
      title: Text(report.reason),
      content: SizedBox(
        width: 500, // Make it wider for desktop/tablet
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'معلومات المُبلّغ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              reporterAsync.when(
                data: (user) {
                  if (user == null) {
                    return Text(
                      'لم يتم العثور على معلومات (${report.reporterId})',
                    );
                  }
                  return _buildUserDetailsCard(context, user);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('خطأ في تحميل المعلومات: $e'),
              ),
              const SizedBox(height: 16),

              if (reportedAsync != null) ...[
                Text(
                  'المبلَّغ عنه (${report.reportedType})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                reportedAsync.when(
                  data: (user) {
                    if (user == null) {
                      return Text(
                        'لم يتم العثور على معلومات (${report.reportedId})',
                      );
                    }
                    return _buildUserDetailsCard(context, user);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('خطأ في تحميل المعلومات: $e'),
                ),
                const SizedBox(height: 16),
              ],

              if (report.tripId != null || report.bookingId != null) ...[
                const Text(
                  'معلومات الرحلة / الحجز',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                if (report.tripId != null) Text('رقم الرحلة: ${report.tripId}'),
                if (report.bookingId != null)
                  Text('رقم الحجز: ${report.bookingId}'),
                const SizedBox(height: 16),
              ],

              const Text(
                'تفاصيل البلاغ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              Text(report.description),
              const SizedBox(height: 16),

              if (report.attachments.isNotEmpty) ...[
                const Text(
                  'المرفقات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: report.attachments
                      .map(
                        (url) => GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(16),
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: Center(
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'تغيير الحالة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: report.status,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('مفتوح')),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('قيد الانتظار'),
                  ),
                  DropdownMenuItem(
                    value: 'investigating',
                    child: Text('قيد التحقيق'),
                  ),
                  DropdownMenuItem(value: 'resolved', child: Text('محلول')),
                  DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                  DropdownMenuItem(value: 'closed', child: Text('مغلق')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(adminSupportRepositoryProvider)
                        .updateReportStatus(report.id, val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final repo = ref.read(
              supportChatRepositoryProvider(report.reporterType),
            );
            final conv = await repo.createConversationForReport(
              report.reporterId,
              report.id,
            );
            if (context.mounted) {
              Navigator.pop(context);
              context.push(
                '/admin/operations/support/chat/${conv.conversationId}',
                extra: conv,
              );
            }
          },
          child: const Text('فتح محادثة', style: TextStyle(color: Colors.blue)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildUserDetailsCard(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user['profileImage'] != null && user['profileImage'].isNotEmpty)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
                              user['profileImage'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(user['profileImage']),
              ),
            )
          else
            const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاسم: ${user['name'] ?? 'غير متوفر'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('رقم الهاتف: ${user['phone'] ?? 'غير متوفر'}'),
                Text('حالة الحساب: ${user['status'] ?? 'غير متوفر'}'),
                Text('موثق: ${user['isVerified'] == true ? 'نعم' : 'لا'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
