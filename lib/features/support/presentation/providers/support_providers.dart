import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/support_conversation.dart';
import '../../domain/models/support_ticket.dart';
import '../../domain/models/support_report.dart';
import '../../domain/models/support_faq.dart';
import '../../data/repositories/support_chat_repository_impl.dart';

import '../../domain/repositories/support_repository.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final supportRepositoryProvider = Provider.family<SupportRepository, String>((
  ref,
  userType,
) {
  return SupportRepositoryImpl(
    FirebaseFirestore.instance,
    collectionPrefix: userType,
  );
});

final supportChatRepositoryProvider =
    Provider.family<SupportChatRepositoryImpl, String>((ref, userType) {
      return SupportChatRepositoryImpl(
        FirebaseFirestore.instance,
        collectionPrefix: userType,
      );
    });

final supportFaqsProvider = StreamProvider.autoDispose
    .family<List<SupportFaq>, String>((ref, userType) {
      final repo = ref.watch(supportRepositoryProvider(userType));
      if (repo is SupportRepositoryImpl) {
        repo.seedFaqsIfEmpty();
      }
      return repo.watchFaqs();
    });

final contactInfoProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userType) {
      return ref.watch(supportRepositoryProvider(userType)).watchContact();
    });

final supportTicketsProvider =
    StreamProvider.family<List<SupportTicket>, String>((ref, userType) {
      final authState = ref.watch(authProvider);
      if (authState is Authenticated) {
        return ref
            .watch(supportRepositoryProvider(userType))
            .watchMyTickets(authState.user.uid);
      }
      return Stream.value([]);
    });

final supportReportsProvider = StreamProvider.autoDispose
    .family<List<SupportReport>, String>((ref, userType) {
      final authState = ref.watch(authProvider);
      if (authState is Authenticated) {
        return ref
            .watch(supportRepositoryProvider(userType))
            .watchMyReports(authState.user.uid);
      }
      return Stream.value([]);
    });

final supportConversationsProvider = FutureProvider<List<SupportConversation>>((
  ref,
) async {
  return [];
});
