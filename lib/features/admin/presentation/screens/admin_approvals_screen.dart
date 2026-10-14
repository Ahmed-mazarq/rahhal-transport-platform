import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rahal/core/theme/admin_theme.dart';
import 'package:rahal/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:rahal/features/common/models/user_model.dart';
import 'package:rahal/features/common/models/driver_model.dart';

class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AdminTheme.background,
        appBar: AppBar(
          backgroundColor: AdminTheme.card,
          title: const Text(
            'طلبات اعتماد الحسابات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),
          iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
          bottom: const TabBar(
            labelColor: AdminTheme.primary,
            unselectedLabelColor: AdminTheme.textSecondary,
            indicatorColor: AdminTheme.primary,
            labelStyle: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: 'السائقين'),
              Tab(text: 'شركات النقل'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RoleApprovalsList(role: 'driver'),
            _RoleApprovalsList(role: 'company'),
          ],
        ),
      ),
    );
  }
}

class _RoleApprovalsList extends StatefulWidget {
  final String role;
  const _RoleApprovalsList({required this.role});

  @override
  State<_RoleApprovalsList> createState() => _RoleApprovalsListState();
}

class _RoleApprovalsListState extends State<_RoleApprovalsList>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final List<String> _statuses = [
    'pending_review',
    'approved',
    'rejected',
    'need_modification',
    'blocked',
  ];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم، رقم الهاتف...',
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.search, color: AdminTheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminTheme.border),
              ),
            ),
          ),
        ),
        TabBar(
          controller: _subTabController,
          isScrollable: true,
          labelColor: AdminTheme.primary,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor: AdminTheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'قيد المراجعة'),
            Tab(text: 'معتمد'),
            Tab(text: 'مرفوض'),
            Tab(text: 'بحاجة لتعديل'),
            Tab(text: 'موقوف'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: _statuses
                .map(
                  (s) => _StatusList(
                    role: widget.role,
                    status: s,
                    searchQuery: _searchQuery,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StatusList extends ConsumerWidget {
  final String role;
  final String status;
  final String searchQuery;

  const _StatusList({
    required this.role,
    required this.status,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(adminUsersRepositoryProvider)
        .streamUsers(role: role, status: status);

    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          );
        }

        var users = snapshot.data ?? [];

        if (searchQuery.isNotEmpty) {
          users = users.where((u) {
            return u.fullName.toLowerCase().contains(searchQuery) ||
                u.phone.contains(searchQuery) ||
                u.id.toLowerCase().contains(searchQuery);
          }).toList();
        }

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد طلبات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                color: AdminTheme.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AdminTheme.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: AdminTheme.primary.withValues(alpha: 0.1),
                  backgroundImage: user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : null,
                  child: user.profileImage.isEmpty
                      ? Icon(
                          role == 'driver' ? Icons.person : Icons.business,
                          color: AdminTheme.primary,
                        )
                      : null,
                ),
                title: Text(
                  user.fullName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'رقم الهاتف: ${user.phone}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تاريخ التسجيل: ${user.createdAt.toString().split(".")[0]}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    if (role == 'driver') ...[
                      const SizedBox(height: 4),
                      FutureBuilder<DriverModel?>(
                        future: ref
                            .read(adminUsersRepositoryProvider)
                            .getDriverById(user.id),
                        builder: (context, driverSnapshot) {
                          if (!driverSnapshot.hasData ||
                              driverSnapshot.data == null) {
                            return const Text(
                              'الوثائق: جاري التحميل...',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AdminTheme.textSecondary,
                              ),
                            );
                          }
                          final docs = driverSnapshot.data!.documents;
                          int total = 11;
                          int uploadedOrApproved = docs.values
                              .where(
                                (d) =>
                                    d.status == 'uploaded' ||
                                    d.status == 'approved',
                              )
                              .length;
                          return Text(
                            'الوثائق: $uploadedOrApproved / $total',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: uploadedOrApproved == total
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                trailing: _buildStatusBadge(user.status),
                onTap: () {
                  context.push('/admin/approvals/details/${user.uid}');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'معتمد';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوض';
        break;
      case 'need_modification':
        color = Colors.orange;
        label = 'تعديل';
        break;
      case 'blocked':
        color = Colors.grey;
        label = 'موقوف';
        break;
      default:
        color = Colors.blue;
        label = 'مراجعة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
