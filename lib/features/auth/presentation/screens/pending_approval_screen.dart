import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/features/auth/presentation/widgets/auth_theme_wrapper.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthThemeWrapper(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'حالة مراجعة الحساب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1F3A),
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Animated Clock/Check Icon Card
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        size: 46,
                        color: Color(0xFFF5A623),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'طلبك قيد المراجعة والتدقيق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يقوم فريق إدارة رحال حالياً بمراجعة مستنداتك وبيانات مركبتك للتحقق من مطابقتها لمعايير الأمان والجودة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Status Timeline Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مسار التفعيل والاعتماد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1F3A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTimelineItem(
                          title: 'تم إنشاء الحساب وتوثيقه',
                          subtitle: 'تم التحقق من بيانات الاتصال',
                          isDone: true,
                          isCurrent: false,
                        ),
                        _buildTimelineItem(
                          title: 'تم رفع المستندات المشفرة',
                          subtitle: '11 مستند جاهز للمطابقة والتدقيق',
                          isDone: true,
                          isCurrent: false,
                        ),
                        _buildTimelineItem(
                          title: 'قيد المراجعة من الإدارة',
                          subtitle: 'يتم فحص الرخص والمركبة والهوية حالياً',
                          isDone: false,
                          isCurrent: true,
                        ),
                        _buildTimelineItem(
                          title: 'اعتماد الحساب وبدء الرحلات',
                          subtitle: 'ستتلقى إشعاراً فور اكتمال التفعيل',
                          isDone: false,
                          isCurrent: false,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Support CTA
                  OutlinedButton.icon(
                    onPressed: () => context.push('/driver-support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B1F3A),
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.headset_mic_rounded, size: 20),
                    label: const Text(
                      'تواصل مع الدعم الفني',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout button
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'تسجيل الخروج والعودة لاحقاً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFF10B981)
                    : (isCurrent
                        ? const Color(0xFFF5A623)
                        : const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : (isCurrent
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          )
                        : null),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? const Color(0xFF0B1F3A)
                      : (isDone
                          ? const Color(0xFF0B1F3A)
                          : const Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
