import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/driver_providers.dart';
import '../providers/driver_profile_image_provider.dart';
import '../../domain/models/driver_profile.dart';
import '../widgets/driver_avatar.dart';
import '../utils/driver_tokens.dart';
import '../utils/driver_status_ui.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(driverProfileProvider);
    final imageState = ref.watch(driverProfileImageProvider).value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101928)
            : DriverTokens.lightBackground,
        body: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: DriverTokens.accentGold),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: DriverTokens.semanticError,
                ),
                const SizedBox(height: 12),
                const Text(
                  'حدث خطأ في تحميل الملف الشخصي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(driverProfileProvider),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text(
                  'لا توجد بيانات متاحة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, profile, isDark, imageState),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(DriverTokens.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(context, profile),
                        const SizedBox(height: DriverTokens.spaceLg),

                        _buildSectionTitle(context, 'إدارة الحساب'),
                        _buildListTile(
                          context,
                          Icons.person_outline_rounded,
                          'المعلومات الشخصية',
                          () => context.push('/driver/profile-management'),
                        ),
                        _buildListTile(
                          context,
                          Icons.map_outlined,
                          'مناطق العمل المدعومة',
                          () => context.push('/working-areas'),
                        ),
                        _buildListTile(
                          context,
                          Icons.payment_outlined,
                          'طرق الدفع واستلام الأرباح',
                          () => context.push('/payment-methods'),
                        ),
                        _buildListTile(
                          context,
                          Icons.document_scanner_outlined,
                          'مركز الوثائق المهني',
                          () => context.push('/driver-documents'),
                        ),
                        _buildListTile(
                          context,
                          Icons.directions_car_outlined,
                          'أسطول المركبات',
                          () => context.push('/driver-vehicles'),
                        ),

                        const SizedBox(height: DriverTokens.spaceLg),
                        _buildSectionTitle(context, 'الأداء والنشاط'),
                        _buildListTile(
                          context,
                          Icons.insights_rounded,
                          'مؤشرات الأداء والإحصائيات',
                          () => context.push('/driver-stats'),
                        ),
                        _buildListTile(
                          context,
                          Icons.history_rounded,
                          'النشاط الأخير',
                          () => context.push('/driver-activity'),
                        ),

                        const SizedBox(height: DriverTokens.spaceLg),
                        _buildSectionTitle(context, 'المساعدة والإعدادات'),
                        _buildListTile(
                          context,
                          Icons.settings_outlined,
                          'إعدادات التطبيق',
                          () => context.push('/settings'),
                        ),
                        _buildListTile(
                          context,
                          Icons.help_outline_rounded,
                          'مركز المساعدة ودعم السائقين',
                          () => context.push('/driver-support'),
                        ),

                        const SizedBox(height: DriverTokens.spaceXl),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                              context.go('/login');
                            },
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: DriverTokens.semanticError,
                            ),
                            label: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                color: DriverTokens.semanticError,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: DriverTokens.semanticError,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DriverTokens.radiusSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    DriverProfile profile,
    bool isDark,
    dynamic imageState,
  ) {
    final statusUi = DriverAccountStatusUi.fromStatus(profile.status);

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: DriverTokens.primaryNavy,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [DriverTokens.primaryNavy, Color(0xFF071426)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  DriverAvatar(
                    imageUrl: imageState?.url ?? profile.profileImage,
                    cacheKey:
                        '${profile.id}_${imageState?.updatedAt ?? profile.profileImageUpdatedAt ?? 0}',
                    radius: 46,
                  ),

                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: profile.isOnline
                          ? DriverTokens.semanticSuccess
                          : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName
                        : 'كابتن رحال',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (profile.status == 'approved') ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: DriverTokens.accentGold,
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusUi.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: statusUi.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusUi.icon, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          statusUi.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.phoneNumber.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text(
                      profile.phoneNumber,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DriverProfile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(DriverTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            Icons.star_rounded,
            DriverTokens.accentGold,
            profile.completedTrips > 0 && profile.rating > 0
                ? profile.rating.toStringAsFixed(1)
                : '—',
            'التقييم العام',
          ),

          _buildStatItem(
            context,
            Icons.task_alt_rounded,
            DriverTokens.semanticSuccess,
            profile.completedTrips.toString(),
            'رحلة مكتملة',
          ),
          _buildStatItem(
            context,
            Icons.people_alt_rounded,
            DriverTokens.semanticInfo,
            profile.totalPassengers.toString(),
            'راكب مؤكد',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Cairo',
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: DriverTokens.spaceSm,
        top: DriverTokens.spaceXs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DriverTokens.primaryNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DriverTokens.primaryNavy, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
