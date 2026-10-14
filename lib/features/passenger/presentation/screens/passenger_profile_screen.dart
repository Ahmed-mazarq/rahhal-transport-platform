import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/profile_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/passenger_providers.dart';
import '../../../../core/constants/location_data.dart';
import '../../domain/models/passenger_profile.dart';
import '../../../../core/providers/repository_providers.dart';
import '../utils/passenger_account_status.dart';
import 'package:rahal/features/dashboard/presentation/providers/passenger_navigation_provider.dart';

class PassengerProfileScreen extends ConsumerWidget {
  const PassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final authState = ref.watch(authProvider);
    final profileState = ref.watch(passengerProfileProvider);

    String name = 'مستخدم';
    String phone = '';
    String rawUserStatus = 'active';
    String profileImage = '';
    bool isUserVerified = false;

    if (authState is Authenticated) {
      name = authState.user.fullName.isNotEmpty
          ? authState.user.fullName
          : 'راكب';
      phone = authState.user.phone;
      rawUserStatus = authState.user.status;
      profileImage = authState.user.profileImage;
      isUserVerified = authState.user.isVerified;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'حسابي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              ref.read(passengerTabIndexProvider.notifier).state = 0;
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          final localizedStatus = PassengerAccountStatus.toArabic(
            profile?.status.isNotEmpty == true
                ? profile!.status
                : rawUserStatus,
          );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Premium Profile Hero Header
                _buildProfileHero(
                  context: context,
                  name: name,
                  phone: phone,
                  profileImage: profileImage,
                  isVerified: isUserVerified,
                  accountStatusText: localizedStatus,
                  isDark: isDark,
                  primaryNavy: primaryNavy,
                  accentGold: accentGold,
                ),

                const SizedBox(height: 16),

                // Real Stats Row (Trip count, Favorite drivers, Saved places)
                if (profile != null)
                  _buildStatsRow(profile, isDark, primaryNavy, accentGold),

                const SizedBox(height: 20),

                // Section 1: إدارة الحساب
                _buildSectionHeader('إدارة الحساب', isDark),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    ProfileCard(
                      title: 'تعديل الملف الشخصي',
                      subtitle: 'تحديث بياناتك الشخصية والصورة',
                      icon: Icons.person_outline_rounded,
                      onTap: () => context.push('/passenger/profile-management'),
                    ),
                    ProfileCard(
                      title: 'المنطقة والمحافظة',
                      subtitle: profile != null && profile.country.isNotEmpty
                          ? '${profile.country} - ${profile.governorate} - ${profile.district}'
                          : 'لم يتم التحديد',
                      icon: Icons.location_on_outlined,
                      onTap: () {
                        if (profile != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                _LocationSelectorSheet(profile: profile),
                          );
                        }
                      },
                    ),
                    ProfileCard(
                      title: 'حالة الحساب',
                      subtitle: 'حالة الحساب: $localizedStatus',
                      icon: Icons.security_outlined,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const _AccountStatusSheet(),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Section 2: رحلاتي
                _buildSectionHeader('رحلاتي', isDark),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    ProfileCard(
                      title: 'سجل الرحلات',
                      subtitle: 'جميع رحلاتك السابقة وتقييماتك',
                      icon: Icons.history_rounded,
                      onTap: () => context.push('/trip-history'),
                    ),
                    ProfileCard(
                      title: 'المفضلة',
                      subtitle: 'السائقون والأماكن المفضلة لديك',
                      icon: Icons.favorite_outline_rounded,
                      onTap: () => context.push('/favorites'),
                    ),
                    ProfileCard(
                      title: 'جهات الاتصال للطوارئ',
                      subtitle: 'إدارة جهات الاتصال الخاصة بالطوارئ',
                      icon: Icons.contact_phone_outlined,
                      onTap: () => context.push('/emergency-contacts'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Section 3: المساعدة والإعدادات
                _buildSectionHeader('المساعدة والإعدادات', isDark),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    ProfileCard(
                      title: 'مركز المساعدة والدعم',
                      subtitle: 'تذاكر الدعم والأسئلة الشائعة',
                      icon: Icons.support_agent_rounded,
                      onTap: () => context.push('/support'),
                    ),
                    ProfileCard(
                      title: 'الإعدادات',
                      subtitle: 'اللغة، الإشعارات، والسمة',
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/settings'),
                    ),
                    ProfileCard(
                      title: 'تسجيل الخروج',
                      subtitle: 'تسجيل الخروج من هذا الحساب',
                      icon: Icons.logout_rounded,
                      isDestructive: true,
                      onTap: () => _showLogoutConfirmation(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => _buildProfileSkeleton(isDark),
        error: (err, stack) => _buildErrorState(ref, isDark, primaryNavy),
      ),
    );
  }

  Widget _buildProfileHero({
    required BuildContext context,
    required String name,
    required String phone,
    required String profileImage,
    required bool isVerified,
    required String accountStatusText,
    required bool isDark,
    required Color primaryNavy,
    required Color accentGold,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with robust error fallback
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentGold, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: primaryNavy.withValues(alpha: 0.12),
                  child: ClipOval(
                    child: profileImage.isNotEmpty
                        ? Image.network(
                            profileImage,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: primaryNavy,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentGold,
                                  ),
                                ),
                              );
                            },
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: primaryNavy,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: () => context.push('/passenger/profile-management'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name and ONLY verified if user.isVerified is explicitly true
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.blue,
                  size: 18,
                ),
              ],
            ],
          ),

          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textDirection: TextDirection.ltr,
            ),
          ],

          const SizedBox(height: 10),

          // Account Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accountStatusText == 'نشط'
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accountStatusText == 'نشط'
                        ? Colors.green
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  accountStatusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accountStatusText == 'نشط'
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    PassengerProfile profile,
    bool isDark,
    Color primaryNavy,
    Color accentGold,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              title: 'الرحلات المكتملة',
              value: '${profile.tripCount}',
              icon: Icons.task_alt_rounded,
              color: Colors.green,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatItem(
              title: 'السائقون المفضلون',
              value: '${profile.favoriteDrivers.length}',
              icon: Icons.person_pin_circle_rounded,
              color: accentGold,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatItem(
              title: 'الأماكن المحفوظة',
              value: '${profile.favoritePlaces.length}',
              icon: Icons.bookmark_border_rounded,
              color: Colors.blue,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildProfileSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, bool isDark, Color primaryNavy) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل بيانات الحساب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تحقق من الاتصال بالإنترنت ثم أعد المحاولة.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.invalidate(passengerProfileProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class _LocationSelectorSheet extends ConsumerStatefulWidget {
  final PassengerProfile profile;
  const _LocationSelectorSheet({required this.profile});

  @override
  ConsumerState<_LocationSelectorSheet> createState() =>
      _LocationSelectorSheetState();
}

class _LocationSelectorSheetState
    extends ConsumerState<_LocationSelectorSheet> {
  int _step = 0; // 0: Country, 1: Governorate, 2: District
  String _selectedCountry = '';
  String _selectedGovernorate = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<String> _getCurrentList() {
    List<String> list = [];
    if (_step == 0) {
      list = locationData.keys.toList();
    } else if (_step == 1) {
      if (locationData.containsKey(_selectedCountry)) {
        list = locationData[_selectedCountry]!.keys.toList();
      }
    } else if (_step == 2) {
      if (locationData.containsKey(_selectedCountry) &&
          locationData[_selectedCountry]!.containsKey(_selectedGovernorate)) {
        list = locationData[_selectedCountry]![_selectedGovernorate]!;
      }
    }

    if (_searchQuery.isNotEmpty) {
      return list
          .where((element) => element.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  void _onItemSelected(String item) async {
    if (_step == 0) {
      setState(() {
        _selectedCountry = item;
        _step = 1;
        _searchQuery = '';
        _searchController.clear();
      });
    } else if (_step == 1) {
      setState(() {
        _selectedGovernorate = item;
        _step = 2;
        _searchQuery = '';
        _searchController.clear();
      });
    } else if (_step == 2) {
      final updatedProfile = widget.profile.copyWith(
        country: _selectedCountry,
        governorate: _selectedGovernorate,
        district: item,
        updatedAt: DateTime.now(),
      );

      try {
        await ref
            .read(passengerRepositoryProvider)
            .updatePassengerProfile(updatedProfile);
        ref.invalidate(passengerProfileProvider);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء الحفظ'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _getCurrentList();

    String title = 'اختر الدولة';
    if (_step == 1) title = 'اختر المحافظة';
    if (_step == 2) title = 'اختر المديرية / الحي';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_step > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _step--;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () => _onItemSelected(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountStatusSheet extends ConsumerWidget {
  const _AccountStatusSheet();

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: label == 'رقم الهاتف' ? TextDirection.ltr : null,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(passengerProfileProvider);

    if (authState is! Authenticated) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: Text('الرجاء تسجيل الدخول')),
      );
    }

    final user = authState.user;
    final profile = profileState.valueOrNull;

    String name = user.fullName;
    String phone = user.phone;
    String uid = user.uid;
    bool isVerified = user.isVerified;

    final accountStatus = PassengerAccountStatus.toArabic(
      profile?.status.isNotEmpty == true ? profile!.status : user.status,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'الاسم الكامل',
                      name,
                      Icons.person_outline,
                      isDark,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'رقم الهاتف',
                      phone,
                      Icons.phone_outlined,
                      isDark,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'رقم العضوية',
                      uid,
                      Icons.badge_outlined,
                      isDark,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'حالة الحساب',
                      accountStatus,
                      Icons.security_outlined,
                      isDark,
                      valueColor: accountStatus == 'نشط'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'شارة التحقق',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isVerified ? 'تم التحقق' : 'غير موثق',
                            style: TextStyle(
                              color: isVerified ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
