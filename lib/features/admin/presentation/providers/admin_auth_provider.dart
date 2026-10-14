import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// Represents the currently logged-in Admin's profile and RBAC permissions.
// In a true production environment, this streams from Firebase Auth / Firestore.
class AdminProfile {
  final String uid;
  final String name;
  final String roleName;
  final List<String> permissions;
  final bool isSuperAdmin;

  AdminProfile({
    required this.uid,
    required this.name,
    required this.roleName,
    required this.permissions,
    this.isSuperAdmin = false,
  });

  bool hasPermission(String requiredPermission) {
    if (isSuperAdmin) return true;
    return permissions.contains(requiredPermission);
  }
}

// Mocking the current admin to demonstrate Enterprise RBAC validation.
final currentAdminProvider = Provider<AdminProfile?>((ref) {
  final authState = ref.watch(authProvider);

  if (authState is Authenticated && authState.user.role == 'admin') {
    return AdminProfile(
      uid: authState.user.id,
      name: authState.user.name,
      roleName: 'Super Admin',
      permissions: [
        'view_all',
        'edit_all',
        'delete_all',
        'approve_all',
        'export_all',
      ],
      isSuperAdmin: true,
    );
  }

  return null;
});
