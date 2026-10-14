import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rahal/core/theme/app_theme.dart';
import 'package:rahal/features/auth/presentation/widgets/auth_theme_wrapper.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  String _selectedRole = 'passenger'; // passenger, driver, company

  void _onContinue() {
    if (_selectedRole == 'passenger') {
      context.push('/signup-passenger');
    } else if (_selectedRole == 'driver') {
      context.push('/signup-driver');
    } else if (_selectedRole == 'company') {
      context.push('/signup-company');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthThemeWrapper(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0B1F3A),
                size: 20,
              ),
              onPressed: () => context.go('/login'),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'اختر نوع الحساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'حدد طريقة استخدامك لرحال لتهيئة حسابك وتجربتك بالشكل الصحيح.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Cards List
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildRoleCard(
                          role: 'passenger',
                          title: 'حساب راكب',
                          badge: 'سفر وشحن طرود',
                          description:
                              'ابحث عن رحلات بين المدن، احجز مقعدك بكل ثقة، وأرسل الطرود وتابعها مباشرة.',
                          icon: Icons.person_rounded,
                          accentColor: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          role: 'driver',
                          title: 'كابتن مستقل',
                          badge: 'سائق رحلات وطرود',
                          description:
                              'انضم لشبكة كباتن رحال، اعرض رحلاتك واستقبل حجوزات الركاب والطرود بعوائد ممتازة.',
                          icon: Icons.drive_eta_rounded,
                          accentColor: const Color(0xFFF5A623),
                        ),
                        const SizedBox(height: 16),
                        _buildRoleCard(
                          role: 'company',
                          title: 'شركة نقل بري',
                          badge: 'إدارة أساطيل ورحلات',
                          description:
                              'أدر أسطول حافلاتك وسائقيك، ووسع تغطيتك الجغرافية عبر خيارات النقل الجماعي والشحن التجاري.',
                          icon: Icons.directions_bus_rounded,
                          accentColor: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1F3A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      elevation: 2,
                      shadowColor: const Color(0xFF0B1F3A).withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _onContinue,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'متابعة التسجيل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String badge,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedRole == role;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFFFFF)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFF5A623)
              : const Color(0xFFE5E7EB),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedRole = role),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon block
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.14)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? accentColor : const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(width: 16),

                // Text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF0B1F3A)
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF5A623).withValues(alpha: 0.15)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF5A623)
                          : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF5A623),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
