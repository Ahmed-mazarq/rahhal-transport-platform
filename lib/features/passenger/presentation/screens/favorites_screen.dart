import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rahal/core/theme/app_theme.dart';
import 'package:rahal/core/providers/repository_providers.dart';
import '../providers/passenger_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Provider to fetch driver details for favorite drivers
final driverDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, driverId) async {
      if (driverId.isEmpty) return null;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(driverId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    });

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryNavy = AppTheme.primaryColor;
    final accentGold = AppTheme.secondaryColor;

    final profileState = ref.watch(passengerProfileProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'المفضلة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentGold,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: accentGold,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'الأماكن المحفوظة'),
            Tab(text: 'السائقون المفضلون'),
          ],
        ),
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return _buildEmptyState(
              icon: Icons.person_off_outlined,
              title: 'لم يتم العثور على الحساب',
              subtitle: 'يرجى تسجيل الدخول لعرض المفضلة',
              isDark: isDark,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPlacesTab(
                profile.uid,
                profile.favoritePlaces,
                isDark,
                primaryNavy,
                accentGold,
              ),
              _buildDriversTab(
                profile.uid,
                profile.favoriteDrivers,
                isDark,
                primaryNavy,
                accentGold,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('تعذر تحميل المفضلة'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(passengerProfileProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPlaceDialog(context),
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text(
                'إضافة مكان',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildPlacesTab(
    String uid,
    List<Map<String, dynamic>> places,
    bool isDark,
    Color primaryNavy,
    Color accentGold,
  ) {
    if (places.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'لا توجد أماكن محفوظة',
        subtitle:
            'احفظ أماكنك المفضلة (المنزل، العمل، إلخ) لتسهيل البحث عن رحلات سريعة.',
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        final id = place['id']?.toString() ?? index.toString();
        final name = place['name']?.toString() ?? 'مكان محفوظ';
        final address =
            place['address']?.toString() ??
            '${place['city'] ?? ''} ${place['governorate'] ?? ''}'.trim();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place_rounded, color: accentGold, size: 22),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: address.isNotEmpty
                ? Text(
                    address,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  )
                : null,
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red[400],
                size: 20,
              ),
              tooltip: 'حذف',
              onPressed: () async {
                HapticFeedback.selectionClick();
                await ref
                    .read(passengerRepositoryProvider)
                    .removeFavoritePlace(uid, id);
                ref.invalidate(passengerProfileProvider);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriversTab(
    String uid,
    List<String> drivers,
    bool isDark,
    Color primaryNavy,
    Color accentGold,
  ) {
    if (drivers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_pin_circle_outlined,
        title: 'لا يوجد سائقون في المفضلة',
        subtitle:
            'أضف سائقيك المفضلين من تفاصيل الرحلات للوصول إليهم مستقبلاً.',
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driverId = drivers[index];
        final driverAsync = ref.watch(driverDetailsProvider(driverId));

        return driverAsync.when(
          data: (driverData) {
            final driverName =
                driverData?['fullName'] ?? driverData?['name'] ?? 'كابتن رحال';
            final phone = driverData?['phone'] ?? '';
            final avatar = driverData?['profileImage']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: primaryNavy.withValues(alpha: 0.1),
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar.isEmpty
                      ? Icon(Icons.person, color: primaryNavy, size: 24)
                      : null,
                ),
                title: Text(
                  driverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: phone.isNotEmpty
                    ? Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textDirection: TextDirection.ltr,
                      )
                    : null,
                trailing: IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red[600], size: 22),
                  tooltip: 'إزالة من المفضلة',
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(passengerRepositoryProvider)
                        .removeFavoriteDriver(uid, driverId);
                    ref.invalidate(passengerProfileProvider);
                  },
                ),
              ),
            );
          },
          loading: () => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252525)
                    : const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlaceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إضافة مكان مفضل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المكان (مثال: المنزل، العمل)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'العنوان أو المدينة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final authState = ref.read(authProvider);
              if (authState is Authenticated) {
                final place = {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': name,
                  'address': addressCtrl.text.trim(),
                  'createdAt': DateTime.now().toIso8601String(),
                };
                await ref
                    .read(passengerRepositoryProvider)
                    .addFavoritePlace(authState.user.uid, place);
                ref.invalidate(passengerProfileProvider);
              }
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
