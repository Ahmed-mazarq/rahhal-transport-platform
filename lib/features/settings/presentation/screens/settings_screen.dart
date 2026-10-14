import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/widgets/profile_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/biometric_service.dart';
import '../../domain/models/app_settings.dart';
import 'change_password_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(l10n.preferences),

          _buildToggleSetting(
            isDark: isDark,
            title: l10n.bookingNotifications,
            icon: Icons.directions_car,
            value: settings.bookingNotifications,
            onChanged: (val) => settingsNotifier.updateSettings(
              settings.copyWith(bookingNotifications: val),
            ),
          ),
          _buildToggleSetting(
            isDark: isDark,
            title: l10n.systemNotifications,
            icon: Icons.notifications,
            value: settings.systemNotifications,
            onChanged: (val) => settingsNotifier.updateSettings(
              settings.copyWith(systemNotifications: val),
            ),
          ),
          _buildToggleSetting(
            isDark: isDark,
            title: l10n.offersAndAds,
            icon: Icons.local_offer,
            value: settings.offersNotifications,
            onChanged: (val) => settingsNotifier.updateSettings(
              settings.copyWith(offersNotifications: val),
            ),
          ),
          _buildToggleSetting(
            isDark: isDark,
            title: l10n.locationServices,
            icon: Icons.location_on,
            value: settings.locationEnabled,
            onChanged: (val) async {
              if (val) {
                final status = await Permission.location.request();
                if (status.isGranted) {
                  settingsNotifier.updateSettings(
                    settings.copyWith(locationEnabled: true),
                  );
                }
              } else {
                settingsNotifier.updateSettings(
                  settings.copyWith(locationEnabled: false),
                );
              }
            },
          ),
          ProfileCard(
            title: l10n.language,
            subtitle: settings.language == 'ar' ? l10n.arabic : l10n.english,
            icon: Icons.language,
            onTap: () {
              final newLang = settings.language == 'ar' ? 'en' : 'ar';
              settingsNotifier.updateSettings(
                settings.copyWith(language: newLang),
              );
            },
          ),
          ProfileCard(
            title: l10n.appearance,
            subtitle: settings.theme == 'dark' ? l10n.darkMode : l10n.lightMode,
            icon: Icons.dark_mode,
            onTap: () {
              final newTheme = settings.theme == 'dark' ? 'light' : 'dark';
              settingsNotifier.updateSettings(
                settings.copyWith(theme: newTheme),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(l10n.securityAndPrivacy),

          ProfileCard(
            title: l10n.changePassword,
            subtitle: '',
            icon: Icons.lock_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          _buildToggleSetting(
            isDark: isDark,
            title: l10n.biometricLogin,
            icon: Icons.fingerprint,
            value: settings.biometricEnabled,
            onChanged: (val) async {
              if (val) {
                final biometric = ref.read(biometricServiceProvider);
                if (await biometric.isDeviceSupported()) {
                  final authed = await biometric.authenticate(
                    l10n.biometricLogin,
                  );
                  if (authed) {
                    settingsNotifier.updateSettings(
                      settings.copyWith(biometricEnabled: true),
                    );
                  }
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.biometricNotSupported)),
                  );
                }
              } else {
                settingsNotifier.updateSettings(
                  settings.copyWith(biometricEnabled: false),
                );
              }
            },
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(l10n.aboutApp),

          ProfileCard(
            title: l10n.termsAndConditions,
            subtitle: '',
            icon: Icons.description_outlined,
            onTap: () {},
          ),
          ProfileCard(
            title: l10n.privacyPolicy,
            subtitle: '',
            icon: Icons.privacy_tip_outlined,
            onTap: () {},
          ),
          ProfileCard(
            title: l10n.rateApp,
            subtitle: '${l10n.version} 1.0.0',
            icon: Icons.star_border,
            onTap: () {},
          ),

          const SizedBox(height: 32),

          ProfileCard(
            title: l10n.deleteAccount,
            subtitle: '',
            icon: Icons.person_off,
            isDestructive: true,
            onTap: () => _confirmDeleteAccount(context, ref, l10n, settings),
          ),
          ProfileCard(
            title: l10n.logout,
            subtitle: '',
            icon: Icons.logout,
            isDestructive: true,
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildToggleSetting({
    required bool isDark,
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F3A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0B1F3A), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFF5A623),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AppSettings settings,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.confirmDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
      }

      final settingsNotifier = ref.read(settingsProvider.notifier);
      await settingsNotifier.updateSettings(
        settings.copyWith(
          accountStatus: 'deleted',
          deleteRequestedAt: DateTime.now(),
        ),
      );

      // Disable user in Firebase Auth is normally done via Cloud Functions listening to Firestore,
      // but we log them out immediately.
      if (!context.mounted) return;
      await _logout(context, ref);
    }
  }
}
