import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/driver_conversation.dart';
import '../../domain/models/driver_message.dart';
import '../../domain/models/driver_ticket.dart';
import '../../domain/models/driver_report.dart';
import '../../domain/models/driver_faq.dart';
import '../../domain/repositories/driver_chat_repository.dart';
import '../../domain/repositories/driver_support_repository.dart';
import '../../data/repositories/driver_chat_repository_impl.dart';
import '../../data/repositories/driver_support_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// --- Repositories ---

final driverSupportRepositoryProvider = Provider<DriverSupportRepository>((
  ref,
) {
  return DriverSupportRepositoryImpl(ref.watch(firestoreProvider));
});

final driverChatRepositoryProvider = Provider<DriverChatRepository>((ref) {
  return DriverChatRepositoryImpl(ref.watch(firestoreProvider));
});

// --- User ID Helper ---

final _currentDriverIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is Authenticated) {
    return authState.user.uid;
  }
  return null;
});

// --- Chat Providers ---

final driverOpenConversationsProvider =
    StreamProvider.autoDispose<List<DriverConversation>>((ref) {
      final driverId = ref.watch(_currentDriverIdProvider);
      if (driverId == null) return Stream.value([]);

      // Repository is the single source of truth
      return ref
          .watch(driverChatRepositoryProvider)
          .watchActiveConversation(driverId)
          .map((conv) => conv != null ? [conv] : []);
    });

final driverUnreadMessagesCountProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  final driverId = ref.watch(_currentDriverIdProvider);
  if (driverId == null) {
    yield 0;
    return;
  }

  debugPrint('--- WATCH QUERY: driver_support_conversations (unreadCount) ---');
  debugPrint('where: participantIds arrayContains \$driverId');
  // Repository is the single source of truth
  final convosStream = ref
      .watch(driverChatRepositoryProvider)
      .watchActiveConversation(driverId);

  await for (final conv in convosStream) {
    if (conv == null) {
      yield 0;
      continue;
    }
    int count = 0;
    try {
      count += await ref
          .read(driverChatRepositoryProvider)
          .getUnreadMessagesCount(conv.conversationId);
    } catch (e, st) {
      if (e is FirebaseException) {
        debugPrint(
          '--- FIRESTORE ERROR in driverUnreadMessagesCountProvider (messages) ---',
        );
        debugPrint('Code: ${e.code}');
        debugPrint('Message: ${e.message}');
        debugPrint(e.stackTrace?.toString() ?? st.toString());
      }
    }
    yield count;
  }
});

final driverMessagesProvider = StreamProvider.autoDispose
    .family<List<DriverMessage>, String>((ref, conversationId) {
      return ref
          .watch(driverChatRepositoryProvider)
          .watchMessages(conversationId);
    });

// --- Support Providers ---

final driverTicketsProvider = StreamProvider.autoDispose<List<DriverTicket>>((
  ref,
) {
  final driverId = ref.watch(_currentDriverIdProvider);
  if (driverId == null) return Stream.value([]);

  return ref.watch(driverSupportRepositoryProvider).watchMyTickets(driverId);
});

final driverReportsProvider = StreamProvider.autoDispose<List<DriverReport>>((
  ref,
) {
  final driverId = ref.watch(_currentDriverIdProvider);
  if (driverId == null) return Stream.value([]);

  return ref.watch(driverSupportRepositoryProvider).watchMyReports(driverId);
});

final driverFaqsProvider = StreamProvider.autoDispose<List<DriverFaq>>((ref) {
  final repo = ref.read(driverSupportRepositoryProvider);
  repo.seedFaqsIfEmpty();
  return repo.watchFaqs();
});

final driverContactInfoProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
      return ref.watch(driverSupportRepositoryProvider).watchContact();
    });
