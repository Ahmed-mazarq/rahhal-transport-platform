import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_users_repository.dart';
import '../../../../features/common/models/user_model.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository();
});

// Search State Provider
final adminUsersSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

// Filter State Providers
final adminUsersFilterRoleProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final adminUsersFilterStatusProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

// Unified Users Stream Provider
final adminUsersStreamProvider = StreamProvider.autoDispose
    .family<List<UserModel>, String>((ref, defaultRole) {
      final repo = ref.watch(adminUsersRepositoryProvider);
      final searchQuery = ref.watch(adminUsersSearchQueryProvider);
      final filterRole = ref.watch(adminUsersFilterRoleProvider);
      final filterStatus = ref.watch(adminUsersFilterStatusProvider);

      // If a role filter is active, it overrides the default tab role, UNLESS the tab is already filtered by something else.
      // We'll pass defaultRole to indicate which tab we're in (passenger, driver, company, admin, blocked)
      String? role = defaultRole;
      String? status;

      if (defaultRole == 'blocked') {
        role = null; // show all blocked users regardless of role
        status = 'blocked';
      } else {
        status = filterStatus;
        if (filterRole != null && filterRole.isNotEmpty) {
          role = filterRole;
        }
      }

      return repo.streamUsers(
        role: role,
        status: status,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );
    });

// Selected Users for Bulk Actions
final adminSelectedUsersProvider = StateProvider.autoDispose<List<String>>(
  (ref) => [],
);
