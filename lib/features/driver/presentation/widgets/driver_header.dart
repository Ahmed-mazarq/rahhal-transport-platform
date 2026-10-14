import 'package:flutter/material.dart';

import '../../domain/models/driver_profile.dart';
import 'driver_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/driver_profile_image_provider.dart';

class DriverHeader extends ConsumerWidget {
  final DriverProfile profile;

  const DriverHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageState = ref.watch(driverProfileImageProvider);

    final isApproved = profile.isApproved;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0B1F3A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DriverAvatar(
            imageUrl: imageState.value?.url ?? '',
            radius: 32,
            cacheKey: imageState.value?.updatedAt != null
                ? '${imageState.value!.url}_${imageState.value!.updatedAt}'
                : imageState.value?.url ?? '',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName
                        : 'كابتن رحال',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isApproved)
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(isApproved, profile.verificationStatus),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isApproved, String verificationStatus) {
    Color bg = Colors.amber.withValues(alpha: 0.12);
    Color fg = Colors.amber;
    String txt = 'قيد المراجعة';

    if (isApproved) {
      bg = Colors.green.withValues(alpha: 0.12);
      fg = Colors.green;
      txt = 'معتمد';
    } else if (verificationStatus == 'needs_update') {
      bg = Colors.orange.withValues(alpha: 0.12);
      fg = Colors.orange;
      txt = 'تحديث الوثائق';
    } else if (verificationStatus == 'rejected') {
      bg = Colors.red.withValues(alpha: 0.12);
      fg = Colors.red;
      txt = 'موقوف مؤقتاً';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        txt,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
