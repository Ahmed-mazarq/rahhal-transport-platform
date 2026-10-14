import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_users_provider.dart';
import '../../../../features/common/models/user_model.dart';

import 'package:rahal/core/widgets/secure_document_image.dart';

class ResolvedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const ResolvedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: SecureDocumentImage(
          storedReference: imageUrl,
          fit: BoxFit.cover,
          placeholder: Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const _AdminFilterSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = ref.watch(adminSelectedUsersProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة المستخدمين',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (isDesktop && selectedUsers.isNotEmpty)
            _buildBulkActionsBar(selectedUsers),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/admin/users/create'),
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة مدير',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black87),
            tooltip: 'تصدير (CSV)',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(adminUsersStreamProvider);
            },
          ),
        ],
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
            Tab(text: 'الركاب'),
            Tab(text: 'السائقين'),
            Tab(text: 'الشركات'),
            Tab(text: 'المدراء'),
            Tab(text: 'موقوفين'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        ref.read(adminUsersSearchQueryProvider.notifier).state =
                            val,
                    decoration: InputDecoration(
                      hintText: 'البحث بالاسم، الهاتف، البريد، الهوية...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.blue),
                    onPressed: _showFilterDialog,
                    tooltip: 'تصفية متقدمة',
                  ),
                ),
              ],
            ),
          ),

          // Bulk Actions for Mobile
          if (!isDesktop && selectedUsers.isNotEmpty)
            Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedUsers.length} محدد',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          ref
                              .read(adminUsersRepositoryProvider)
                              .bulkUpdateStatus(selectedUsers, 'active')
                              .then(
                                (_) => ref.invalidate(adminUsersStreamProvider),
                              );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.orange),
                        onPressed: () {
                          ref
                              .read(adminUsersRepositoryProvider)
                              .bulkUpdateStatus(selectedUsers, 'blocked')
                              .then(
                                (_) => ref.invalidate(adminUsersStreamProvider),
                              );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref
                              .read(adminUsersRepositoryProvider)
                              .bulkDeleteUsers(selectedUsers)
                              .then((_) {
                                ref
                                        .read(
                                          adminSelectedUsersProvider.notifier,
                                        )
                                        .state =
                                    [];
                                ref.invalidate(adminUsersStreamProvider);
                              });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AdminUsersTabContent(defaultRole: 'passenger'),
                _AdminUsersTabContent(defaultRole: 'driver'),
                _AdminUsersTabContent(defaultRole: 'company'),
                _AdminUsersTabContent(defaultRole: 'admin'),
                _AdminUsersTabContent(defaultRole: 'blocked'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (!isDesktop)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0B1F3A),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => context.push('/admin/users/create'),
            )
          : null,
    );
  }

  Widget _buildBulkActionsBar(List<String> selectedUsers) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${selectedUsers.length} محدد',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text(
              'تفعيل',
              style: TextStyle(color: Colors.green, fontFamily: 'Cairo'),
            ),
            onPressed: () {
              ref
                  .read(adminUsersRepositoryProvider)
                  .bulkUpdateStatus(selectedUsers, 'active')
                  .then((_) => ref.invalidate(adminUsersStreamProvider));
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.block, color: Colors.orange),
            label: const Text(
              'إيقاف',
              style: TextStyle(color: Colors.orange, fontFamily: 'Cairo'),
            ),
            onPressed: () {
              ref
                  .read(adminUsersRepositoryProvider)
                  .bulkUpdateStatus(selectedUsers, 'blocked')
                  .then((_) => ref.invalidate(adminUsersStreamProvider));
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              'حذف',
              style: TextStyle(color: Colors.red, fontFamily: 'Cairo'),
            ),
            onPressed: () {
              ref
                  .read(adminUsersRepositoryProvider)
                  .bulkDeleteUsers(selectedUsers)
                  .then((_) {
                    ref.read(adminSelectedUsersProvider.notifier).state = [];
                    ref.invalidate(adminUsersStreamProvider);
                  });
            },
          ),
        ],
      ),
    );
  }
}

class _AdminUsersTabContent extends ConsumerWidget {
  final String defaultRole;
  const _AdminUsersTabContent({required this.defaultRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(adminUsersStreamProvider(defaultRole));

    return streamAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد بيانات مطابقة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;
            if (isDesktop) {
              return _buildDataTable(context, ref, users);
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) =>
                    _buildUserCard(context, ref, users[index]),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'خطأ: $err',
          style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> users,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: true,
          onSelectAll: (val) {
            if (val == true) {
              ref.read(adminSelectedUsersProvider.notifier).state = users
                  .map((u) => u.id)
                  .toList();
            } else {
              ref.read(adminSelectedUsersProvider.notifier).state = [];
            }
          },
          columns: const [
            DataColumn(
              label: Text(
                'المستخدم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الدور',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'رقم الهاتف',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'تاريخ التسجيل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'التقييم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الحالة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'إجراءات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: users.map((user) {
            final id = user.id;
            final selected = ref.watch(adminSelectedUsersProvider).contains(id);
            return DataRow(
              selected: selected,
              onSelectChanged: (val) {
                final current = ref.read(adminSelectedUsersProvider);
                if (val == true) {
                  ref.read(adminSelectedUsersProvider.notifier).state = [
                    ...current,
                    id,
                  ];
                } else {
                  ref.read(adminSelectedUsersProvider.notifier).state = current
                      .where((uid) => uid != id)
                      .toList();
                }
              },
              cells: [
                DataCell(
                  Row(
                    children: [
                      ResolvedCircleAvatar(imageUrl: user.profileImage),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'بدون اسم',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.email.isNotEmpty)
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(user.role, style: const TextStyle(fontFamily: 'Cairo')),
                ),
                DataCell(
                  Text(
                    user.phone.isNotEmpty ? user.phone : '-',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    user.createdAt.toString().substring(0, 10),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  const Text('-', style: TextStyle(fontFamily: 'Cairo')),
                ),
                DataCell(_buildStatusBadge(user.status)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => context.push(
                          '/admin/users/details/$id',
                          extra: user.toFirestore()..addAll({'id': user.id}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, UserModel user) {
    final id = user.id;
    final selected = ref.watch(adminSelectedUsersProvider).contains(id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(
          '/admin/users/details/$id',
          extra: user.toFirestore()..addAll({'id': user.id}),
        ),
        onLongPress: () {
          final current = ref.read(adminSelectedUsersProvider);
          if (selected) {
            ref.read(adminSelectedUsersProvider.notifier).state = current
                .where((uid) => uid != id)
                .toList();
          } else {
            ref.read(adminSelectedUsersProvider.notifier).state = [
              ...current,
              id,
            ];
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ResolvedCircleAvatar(imageUrl: user.profileImage, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : 'بدون اسم',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user.phone.isNotEmpty ? user.phone : '-',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(user.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconText(Icons.badge, user.role),
                  _buildIconText(Icons.star, '-'),
                  _buildIconText(
                    Icons.calendar_today,
                    user.createdAt.toString().substring(0, 10),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _AdminFilterSheet extends ConsumerWidget {
  const _AdminFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تصفية متقدمة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'الحالة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text(
                  'الكل',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                selected: ref.watch(adminUsersFilterStatusProvider) == null,
                onSelected: (_) =>
                    ref.read(adminUsersFilterStatusProvider.notifier).state =
                        null,
              ),
              ChoiceChip(
                label: const Text('نشط', style: TextStyle(fontFamily: 'Cairo')),
                selected: ref.watch(adminUsersFilterStatusProvider) == 'active',
                onSelected: (_) =>
                    ref.read(adminUsersFilterStatusProvider.notifier).state =
                        'active',
              ),
              ChoiceChip(
                label: const Text(
                  'موقوف',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                selected:
                    ref.watch(adminUsersFilterStatusProvider) == 'blocked',
                onSelected: (_) =>
                    ref.read(adminUsersFilterStatusProvider.notifier).state =
                        'blocked',
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1F3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'تطبيق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
