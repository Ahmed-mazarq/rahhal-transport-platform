import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:rahal/core/widgets/secure_document_image.dart';
import 'package:rahal/features/admin/presentation/widgets/passenger_details_tab.dart';
import 'package:rahal/features/admin/presentation/widgets/driver_details_widgets.dart';
import 'package:rahal/features/admin/presentation/widgets/company_details_widgets.dart';
import '../providers/admin_users_provider.dart';
import '../providers/admin_passenger_details_provider.dart';

class AdminUserDetailsScreen extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic> user;

  const AdminUserDetailsScreen({
    super.key,
    required this.userId,
    required this.user,
  });

  @override
  ConsumerState<AdminUserDetailsScreen> createState() =>
      _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends ConsumerState<AdminUserDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String baseRole = widget.user['role'] ?? 'passenger';

    // Attempt to get updated image from providers
    String imageUrl = widget.user['profileImage'] ?? '';
    if (baseRole == 'passenger') {
      final state = ref.watch(passengerDetailsProvider(widget.userId));
      if (state.user != null && state.user!.profileImage.isNotEmpty) {
        imageUrl = state.user!.profileImage;
      }
    }

    final String name =
        widget.user['fullName'] ?? widget.user['name'] ?? 'بدون اسم';
    final String role = baseRole;
    final String status = widget.user['status'] ?? 'active';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'تفاصيل المستخدم',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (status == 'active' || status == 'approved')
            IconButton(
              icon: const Icon(Icons.block, color: Colors.orange),
              tooltip: 'إيقاف الحساب مؤقتاً',
              onPressed: () => _showSuspendDialog(context, ref),
            ),
          if (status == 'active' || status == 'approved')
            IconButton(
              icon: const Icon(Icons.gavel, color: Colors.red),
              tooltip: 'حظر الحساب نهائياً',
              onPressed: () => _showBlockDialog(context, ref),
            ),
          if (status == 'blocked' || status == 'suspended')
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'تفعيل الحساب',
              onPressed: () => _updateStatus(context, ref, 'active', null),
            ),
          if (status != 'deleted')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'حذف الحساب',
              onPressed: () => _showDeleteDialog(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Profile Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    if (imageUrl.isEmpty) {
                      return const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      );
                    }
                    return ClipOval(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: SecureDocumentImage(
                          storedReference: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
              labelColor: const Color(0xFF0B1F3A),
              indicatorColor: const Color(0xFF0B1F3A),
              isScrollable: true,
              tabs: const [
                Tab(text: 'المعلومات الشخصية'),
                Tab(text: 'الرحلات / الحجوزات'),
                Tab(text: 'المستندات'),
                Tab(text: 'سجل النشاطات'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildTripsTab(role),
                _buildDocumentsTab(role),
                _AdminUserActivityTab(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsTab(String role) {
    if (role == 'passenger') return PassengerDetailsTab(userId: widget.userId);
    if (role == 'driver') return DriverTripsBookingsTab(userId: widget.userId);
    if (role == 'company')
      return CompanyTripsBookingsTab(userId: widget.userId);
    return const Center(
      child: Text(
        'لا توجد بيانات لهذه الصلاحية',
        style: TextStyle(fontFamily: 'Cairo'),
      ),
    );
  }

  Widget _buildDocumentsTab(String role) {
    if (role == 'passenger')
      return const Center(
        child: Text(
          'لا توجد مستندات مطلوبة للراكب',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
      );
    if (role == 'driver') return DriverDocumentsTab(userId: widget.userId);
    if (role == 'company') return CompanyDocumentsTab(userId: widget.userId);
    return const Center(
      child: Text(
        'المستندات متاحة للسائقين والشركات فقط',
        style: TextStyle(fontFamily: 'Cairo'),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
      case 'approved':
        color = Colors.green;
        label = status == 'active' ? 'نشط' : 'معتمد';
        break;
      case 'blocked':
        color = Colors.red;
        label = 'موقوف';
        break;
      case 'pending_review':
        color = Colors.orange;
        label = 'قيد المراجعة';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوض';
        break;
      case 'need_modification':
        color = Colors.orange;
        label = 'تعديل';
        break;
      case 'deleted':
        color = Colors.grey;
        label = 'محذوف';
        break;
      default:
        color = Colors.grey;
        label = status;
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

  Widget _buildPersonalInfoTab() {
    final role = widget.user['role'] ?? '';
    if (role == 'driver') return DriverPersonalInfoTab(userId: widget.userId);
    if (role == 'company') return CompanyPersonalInfoTab(userId: widget.userId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات الاتصال',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text(
                    'رقم الهاتف',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    widget.user['phone'] ?? widget.user['phoneNumber'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text(
                    'البريد الإلكتروني',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    widget.user['email'] ?? widget.user['hiddenEmail'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'معلومات النظام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text(
                    'تاريخ التسجيل',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    widget.user['createdAt']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text(
                    'المعرف الفريد (UID)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    widget.userId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.user['status'] == 'suspended' &&
                    widget.user['suspendedUntil'] != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.orange),
                    title: const Text(
                      'موقوف حتى',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                    subtitle: Text(
                      widget.user['suspendedUntil'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
                if (widget.user['blockReason'] != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: const Text(
                      'سبب الحظر / الإيقاف',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    subtitle: Text(
                      widget.user['blockReason'] ??
                          widget.user['suspensionReason'] ??
                          '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
    String? reason, {
    int? suspensionHours,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref
          .read(adminUsersRepositoryProvider)
          .updateUserManagementStatus(
            widget.userId,
            status,
            blockReason: reason,
            suspensionHours: suspensionHours,
          );

      if (context.mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث الحالة إلى $status بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }

      ref.invalidate(adminUsersStreamProvider);

      // Update local state to reflect UI changes immediately if needed,
      // but since it's passed from navigation, we might just update the widget.user locally for display purposes
      setState(() {
        widget.user['status'] = status;
      });
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل التحديث: $e',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuspendDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    int selectedHours = 24;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إيقاف الحساب مؤقتاً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'السبب',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedHours,
              items: const [
                DropdownMenuItem(value: 1, child: Text('ساعة واحدة')),
                DropdownMenuItem(value: 24, child: Text('يوم واحد')),
                DropdownMenuItem(value: 72, child: Text('3 أيام')),
                DropdownMenuItem(value: 168, child: Text('أسبوع')),
              ],
              onChanged: (val) {
                if (val != null) selectedHours = val;
              },
              decoration: const InputDecoration(
                labelText: 'المدة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (context.mounted) {
                Navigator.pop(ctx);
                _updateStatus(
                  context,
                  ref,
                  'suspended',
                  reasonController.text,
                  suspensionHours: selectedHours,
                );
              }
            },
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حظر الحساب نهائياً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'سبب الحظر',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (context.mounted) {
                Navigator.pop(ctx);
                _updateStatus(context, ref, 'blocked', reasonController.text);
              }
            },
            child: const Text('حظر'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من حذف هذا الحساب؟ سيتم أرشفة البيانات.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                await ref
                    .read(adminUsersRepositoryProvider)
                    .deleteUserSafely(widget.userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // go back to list
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// _PassengerTripsBookingsTab removed in favor of PassengerDetailsTab
// _DriverTripsBookingsTab removed
// _CompanyTripsBookingsTab removed
// _DriverDocumentsTab removed
// _CompanyDocumentsTab removed

class _AdminUserActivityTab extends StatelessWidget {
  final String userId;

  const _AdminUserActivityTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('audit_logs')
          .where('targetUid', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'تعذر تحميل سجل النشاطات',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      () {}, // Refresh logic would go here if not a stream
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          );
        }

        var docs =
            snapshot.data?.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList() ??
            [];
        if (docs.isEmpty)
          return const Center(
            child: Text(
              'لا يوجد سجل نشاطات',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          );

        docs.sort((a, b) {
          final timeA = a['timestamp'] ?? a['createdAt'];
          final timeB = b['timestamp'] ?? b['createdAt'];
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          if (timeA is Timestamp && timeB is Timestamp)
            return timeB.compareTo(timeA);
          return 0;
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length > 100 ? 100 : docs.length,
          itemBuilder: (context, index) {
            final data = docs[index];
            final action = data['action'] ?? data['description'] ?? 'نشاط';
            final time = data['timestamp'] ?? data['createdAt'];

            String formattedTime = '-';
            if (time is Timestamp) {
              final d = time.toDate();
              formattedTime =
                  '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")} ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
            } else if (time is String) {
              formattedTime = time;
            } else if (time is DateTime) {
              formattedTime =
                  '${time.year}-${time.month.toString().padLeft(2, "0")}-${time.day.toString().padLeft(2, "0")} ${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
            }

            return ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: Text(
                action,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                formattedTime,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}
