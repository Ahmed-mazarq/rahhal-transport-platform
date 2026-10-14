import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Role fields
  final _licenseController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _fleetSizeController = TextEditingController();

  String _selectedRole = 'passenger'; // passenger, driver, company
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _nameController.dispose();
    _commercialRegisterController.dispose();
    _fleetSizeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب الموافقة على الشروط والأحكام للمتابعة.',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> roleFields = {};
    if (_selectedRole == 'driver') {
      roleFields['licenseNumber'] = _licenseController.text.trim();
    } else if (_selectedRole == 'company') {
      roleFields['name'] = _nameController.text.trim();
      roleFields['commercialRegister'] = _commercialRegisterController.text
          .trim();
      roleFields['fleetSize'] = int.tryParse(_fleetSizeController.text) ?? 0;
    }

    await ref
        .read(authProvider.notifier)
        .register(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          roleFields: roleFields,
        );

    final state = ref.read(authProvider);
    if (state is AuthError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.message,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (state is Authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الحساب بنجاح!',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _redirect(state.user.role);
      }
    }
  }

  void _redirect(String role) {
    if (role == 'passenger') {
      context.go('/dashboard');
    } else if (role == 'driver') {
      context.go('/driver-dashboard');
    } else if (role == 'company') {
      context.go('/company-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0C131F)
            : const Color(0xFFF7F8FA),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1F3A).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 48,
                    color: Color(0xFFF5A623),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'انضم لمنصة رحال لنقل آمن وموثوق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                // Register Form Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Account Type Selector
                          const Text(
                            'نوع الحساب',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildRoleButton('passenger', 'راكب'),
                              const SizedBox(width: 8),
                              _buildRoleButton('driver', 'سائق'),
                              const SizedBox(width: 8),
                              _buildRoleButton('company', 'شركة نقل'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'الاسم الكامل',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'يرجى إدخال الاسم الكامل'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'رقم الهاتف الجوال',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.phone_android_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'يرجى إدخال رقم الهاتف';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'يرجى إدخال كلمة المرور';
                              }
                              if (val.length < 8) {
                                return 'يجب أن لا تقل كلمة المرور عن ٨ خانات';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'يرجى تأكيد كلمة المرور';
                              }
                              if (val != _passwordController.text) {
                                return 'كلمات المرور غير متطابقة';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Role Fields
                          if (_selectedRole == 'driver') ...[
                            TextFormField(
                              controller: _licenseController,
                              decoration: InputDecoration(
                                labelText: 'رقم رخصة القيادة',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'رقم الرخصة مطلوب للسائقين'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ] else if (_selectedRole == 'company') ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'اسم الشركة الرسمي',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.business_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'اسم الشركة مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _commercialRegisterController,
                              decoration: InputDecoration(
                                labelText: 'السجل التجاري',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.receipt_long_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'رقم السجل التجاري مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fleetSizeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'حجم أسطول المركبات',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.directions_car_filled_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'يرجى تحديد حجم الأسطول'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Checkbox Terms
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (val) =>
                                    setState(() => _acceptTerms = val ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'أوافق على الشروط والأحكام و سياسة الخصوصية.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          if (authState is AuthLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF5A623),
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B1F3A),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _submit,
                              child: const Text(
                                'إنشاء حساب',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Go back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لديك حساب بالفعل؟',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5A623),
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
    );
  }

  Widget _buildRoleButton(String role, String title) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF0B1F3A).withValues(alpha: 0.08)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF0B1F3A)
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => setState(() => _selectedRole = role),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF0B1F3A) : Colors.grey,
          ),
        ),
      ),
    );
  }
}
