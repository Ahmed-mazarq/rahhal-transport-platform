import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(
      systemStreamProvider(SystemCollectionParams('admin_roles')),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة الصلاحيات (RBAC)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: streamAsync.when(
        data: (roles) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الأدوار والصلاحيات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'قم بإدارة الأدوار المتاحة في النظام وتحديد صلاحيات كل دور بدقة.',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
                const SizedBox(height: 24),

                if (roles.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'لا توجد أدوار مضافة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roles.length,
                    itemBuilder: (context, index) =>
                        _buildRoleCard(context, roles[index]),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.security),
        label: const Text(
          'إضافة دور جديد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, Map<String, dynamic> role) {
    final isSystemRole = role['isSystem'] == true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isSystemRole
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            Icons.shield,
            color: isSystemRole ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(
          role['name'] ?? 'بدون اسم',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isSystemRole ? 'دور نظام (غير قابل للحذف)' : 'دور مخصص',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isSystemRole ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'صلاحيات هذا الدور:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ((role['permissions'] as List<dynamic>?) ?? []).map(
                    (perm) {
                      return Chip(
                        label: Text(
                          perm.toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                      );
                    },
                  ).toList(),
                ),
                const SizedBox(height: 16),
                if (!isSystemRole)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'حذف الدور',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        label: const Text(
                          'تعديل الصلاحيات',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
