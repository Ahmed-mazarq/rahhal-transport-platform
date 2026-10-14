import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_auth_provider.dart';

class AdminPermissionGate extends ConsumerWidget {
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;

  const AdminPermissionGate({
    super.key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider);

    if (admin == null) {
      return fallback ?? const SizedBox.shrink();
    }

    if (admin.hasPermission(requiredPermission)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
