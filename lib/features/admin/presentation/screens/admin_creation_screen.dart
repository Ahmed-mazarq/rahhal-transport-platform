import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/admin_users_repository.dart';

class AdminCreationScreen extends ConsumerStatefulWidget {
  const AdminCreationScreen({super.key});

  @override
  ConsumerState<AdminCreationScreen> createState() =>
      _AdminCreationScreenState();
}

class _AdminCreationScreenState extends ConsumerState<AdminCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _email = '';
  String _password = '';
  String _selectedRole = 'operations_manager';

  bool _isLoading = false;

  final List<String> _roles = [
    'super_admin',
    'operations_manager',
    'support_manager',
    'fleet_manager',
    'finance_manager',
    'compliance_manager',
    'analytics_manager',
    'read_only',
  ];

  final Map<String, List<String>> _permissions = {
    'users': ['view', 'create', 'edit', 'delete'],
    'drivers': ['view', 'create', 'edit', 'delete', 'approve'],
    'companies': ['view', 'create', 'edit', 'delete', 'approve'],
    'trips': ['view', 'edit', 'export'],
    'bookings': ['view', 'edit', 'export'],
    'documents': ['view', 'approve', 'reject'],
    'reports': ['view', 'export'],
    'support': ['view', 'edit'],
  };

  final Map<String, Map<String, bool>> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    // Initialize permissions
    for (var module in _permissions.keys) {
      _selectedPermissions[module] = {};
      for (var perm in _permissions[module]!) {
        _selectedPermissions[module]![perm] = false;
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> adminData = {
        'fullName': _name,
        'phone': _phone,
        'email': _email,
        'password':
            _password, // Note: In production, do NOT store plain text. Use Firebase Auth CreateUser.
        'role': _selectedRole,
        'status': 'active',
        'permissions': _selectedPermissions,
      };

      await AdminUsersRepository().createAdminUser(adminData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء حساب المدير بنجاح')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إضافة مدير جديد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المعلومات الأساسية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'الاسم الكامل',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'مطلوب' : null,
                              onSaved: (val) => _name = val!,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'رقم الهاتف',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'مطلوب'
                                        : null,
                                    onSaved: (val) => _phone = val!,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'البريد الإلكتروني (اختياري)',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSaved: (val) => _email = val ?? '',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'كلمة المرور المؤقتة',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (val) => val == null || val.length < 6
                                  ? 'يجب أن تكون 6 أحرف على الأقل'
                                  : null,
                              onSaved: (val) => _password = val!,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Role & Permissions Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الصلاحيات والدور',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'الدور (Role)',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedRole,
                              items: _roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                  // Optional: Auto-check permissions based on role preset
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'مصفوفة الصلاحيات (Permissions Matrix)',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'الوحدة (Module)',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(label: Text('عرض (View)')),
                                  DataColumn(label: Text('إنشاء (Create)')),
                                  DataColumn(label: Text('تعديل (Edit)')),
                                  DataColumn(label: Text('حذف (Delete)')),
                                  DataColumn(label: Text('تصدير/اعتماد')),
                                ],
                                rows: _permissions.keys.map((module) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          module.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildCheckboxCell(module, 'view'),
                                      _buildCheckboxCell(module, 'create'),
                                      _buildCheckboxCell(module, 'edit'),
                                      _buildCheckboxCell(module, 'delete'),
                                      _buildCheckboxCell(
                                        module,
                                        _permissions[module]!.contains(
                                              'approve',
                                            )
                                            ? 'approve'
                                            : 'export',
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1F3A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'إنشاء الحساب',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  DataCell _buildCheckboxCell(String module, String permission) {
    if (!_permissions[module]!.contains(permission)) {
      return const DataCell(Text('-'));
    }
    return DataCell(
      Checkbox(
        value: _selectedPermissions[module]![permission],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedPermissions[module]![permission] = val;
            });
          }
        },
      ),
    );
  }
}
