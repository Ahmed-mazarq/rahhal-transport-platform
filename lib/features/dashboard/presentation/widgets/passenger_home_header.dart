import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/passenger_hero_illustration.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class PassengerHomeHeader extends ConsumerWidget {
  const PassengerHomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final rawName = user?.name.trim() ?? '';
    final firstName = rawName.isNotEmpty ? rawName.split(' ').first : 'ضيف';
    final profileImageUrl = user?.profileImage.trim() ?? '';
    final initialLetter = firstName.isNotEmpty
        ? firstName.characters.first
        : 'ض';

    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0B1F3A),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Premium Navy Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B1F3A),
                    Color(0xFF13325B),
                    Color(0xFF1A4175),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            // Subtle gold accent shapes in background
            Positioned(
              left: -40,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5A623).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Decorative Travel Hero Illustration (non-intrusive background motion)
            const Positioned(
              left: 12,
              bottom: 6,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.12,
                  child: PassengerHeroIllustration(
                    width: 170,
                    height: 100,
                  ),
                ),
              ),
            ),
            // Header Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 14.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Avatar & Welcome (Tappable)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'الملف الشخصي للمسافر: $firstName',
                        child: InkWell(
                          onTap: () {
                            context.push('/passenger-profile');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 2.0,
                            ),
                            child: Row(
                              children: [
                                // Avatar with gold accent border
                                Hero(
                                  tag: 'passenger_header_avatar',
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFF5A623),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: profileImageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: profileImageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: const Color(
                                                      0xFF143565,
                                                    ),
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Color(
                                                                0xFFF5A623,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      _buildAvatarFallback(
                                                        initialLetter,
                                                      ),
                                            )
                                          : _buildAvatarFallback(initialLetter),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Greeting & Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'مرحباً بك،',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        firstName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'جاهز لرحلتك القادمة؟',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white60,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification Icon with Badge
                    Semantics(
                      button: true,
                      label: unreadCount > 0
                          ? 'الإشعارات، يوجد $unreadCount غير مقروءة'
                          : 'الإشعارات',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            context.push('/notifications');
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5A623),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF0B1F3A),
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 9
                                            ? '9+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF0B1F3A),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initialLetter) {
    return Container(
      color: const Color(0xFF143565),
      child: Center(
        child: Text(
          initialLetter,
          style: const TextStyle(
            color: Color(0xFFF5A623),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
