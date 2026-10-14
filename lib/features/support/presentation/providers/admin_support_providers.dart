import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/admin_support_repository.dart';
import '../../../../core/providers/repository_providers.dart';

import '../../domain/models/support_conversation.dart';
import '../../domain/models/support_ticket.dart';
import '../../domain/models/support_report.dart';
import '../../domain/models/support_message.dart';
import '../../data/repositories/admin_support_repository_impl.dart';
import '../../domain/models/support_faq.dart';
import '../../domain/repositories/support_chat_repository.dart';
import '../../data/repositories/support_chat_repository_impl.dart';

// Provider for Repository
final adminSupportRepositoryProvider = Provider<AdminSupportRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AdminSupportRepositoryImpl(firestore);
});

// Dashboard Stats Stream
final adminDashboardStatsProvider =
    StreamProvider.autoDispose<Map<String, int>>((ref) {
      return ref.watch(adminSupportRepositoryProvider).watchDashboardStats();
    });

typedef AdminSupportFilters = ({
  String? userType,
  String? status,
  String? priority,
  String? reporterType,
});

// Conversations Stream Family
final adminConversationsProvider = StreamProvider.autoDispose
    .family<List<SupportConversation>, AdminSupportFilters>((ref, filters) {
      return ref
          .watch(adminSupportRepositoryProvider)
          .watchConversations(
            userType: filters.userType,
            status: filters.status,
            priority: filters.priority,
          );
    });

// Tickets Stream Family
final adminTicketsProvider = StreamProvider.autoDispose
    .family<List<SupportTicket>, AdminSupportFilters>((ref, filters) {
      return ref
          .watch(adminSupportRepositoryProvider)
          .watchTickets(
            userType: filters.userType,
            status: filters.status,
            priority: filters.priority,
          );
    });

// Reports Stream Family
final adminReportsProvider = StreamProvider.autoDispose
    .family<List<SupportReport>, AdminSupportFilters>((ref, filters) {
      return ref
          .watch(adminSupportRepositoryProvider)
          .watchReports(
            reporterType: filters.reporterType,
            status: filters.status,
          );
    });

// Admin Chat Specific Providers
final adminChatRepositoryProvider =
    Provider.family<SupportChatRepository, String>((ref, userType) {
      return SupportChatRepositoryImpl(
        ref.watch(firestoreProvider),
        collectionPrefix: userType,
      );
    });

typedef AdminChatParams = ({String conversationId, String userType});

final adminConversationMessagesProvider = StreamProvider.autoDispose
    .family<List<SupportMessage>, AdminChatParams>((ref, params) {
      final repo = ref.watch(adminChatRepositoryProvider(params.userType));
      return repo.watchMessages(params.conversationId);
    });

typedef AdminUserDetailsParams = ({String userId, String userType});

final adminUserDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, AdminUserDetailsParams>((ref, params) async {
      final firestore = ref.watch(firestoreProvider);

      try {
        if (params.userType == 'passenger') {
          final doc = await firestore
              .collection('passengers')
              .doc(params.userId)
              .get();
          if (doc.exists) {
            final data = doc.data()!;
            return {
              'name': data['fullName'] ?? data['name'] ?? 'راكب',
              'phone': data['phoneNumber'] ?? data['phone'] ?? 'غير متوفر',
              'totalTrips': data['tripCount'] ?? data['totalTrips'] ?? 0,
              'rating': data['rating'] ?? 0.0,
              'status': data['status'] ?? data['accountStatus'] ?? 'نشط',
              'createdAt': data['createdAt'] ?? data['registrationDate'],
              'city': data['city'] ?? 'غير محدد',
              'country': data['country'] ?? 'غير محدد',
              'role': params.userType,
              'isVerified': data['isVerified'] ?? data['verified'] ?? false,
              'profileImage':
                  data['profileImageUrl'] ??
                  data['avatarUrl'] ??
                  data['profileImage'],
            };
          }
        } else if (params.userType == 'driver') {
          final doc = await firestore
              .collection('drivers')
              .doc(params.userId)
              .get();
          if (doc.exists) {
            final data = doc.data()!;
            return {
              'name': data['fullName'] ?? data['name'] ?? 'سائق',
              'phone': data['phoneNumber'] ?? data['phone'] ?? 'غير متوفر',
              'totalTrips':
                  data['statistics']?['completedTrips'] ??
                  data['totalTrips'] ??
                  0,
              'rating': data['rating'] ?? data['statistics']?['rating'] ?? 0.0,
              'status': data['status'] ?? data['accountStatus'] ?? 'نشط',
              'createdAt': data['createdAt'] ?? data['registrationDate'],
              'city': data['city'] ?? 'غير محدد',
              'country': data['country'] ?? 'غير محدد',
              'role': params.userType,
              'isVerified': data['isVerified'] ?? data['verified'] ?? false,
              'profileImage':
                  data['profileImageUrl'] ??
                  data['avatarUrl'] ??
                  data['profileImage'],
            };
          }
        } else if (params.userType == 'company') {
          final doc = await firestore
              .collection('companies')
              .doc(params.userId)
              .get();
          if (doc.exists) {
            final data = doc.data()!;
            return {
              'name': data['name'] ?? data['name'] ?? 'شركة',
              'phone': data['phoneNumber'] ?? data['phone'] ?? 'غير متوفر',
              'totalTrips': data['totalTrips'] ?? 0,
              'rating': data['rating'] ?? 0.0,
              'status': data['status'] ?? data['accountStatus'] ?? 'نشط',
              'createdAt': data['createdAt'] ?? data['registrationDate'],
              'city': data['city'] ?? 'غير محدد',
              'country': data['country'] ?? 'غير محدد',
              'role': params.userType,
              'isVerified': data['isVerified'] ?? data['verified'] ?? false,
              'profileImage':
                  data['logoUrl'] ??
                  data['profileImageUrl'] ??
                  data['avatarUrl'] ??
                  data['profileImage'],
            };
          }
        }
      } catch (e) {
        debugPrint('Error fetching user details for ${params.userType}: $e');
      }
      return null;
    });

// --- Contacts ---

final adminContactProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userType) {
      return ref.watch(adminSupportRepositoryProvider).watchContact(userType);
    });

// --- FAQs ---

final adminFaqsProvider = StreamProvider.autoDispose
    .family<List<SupportFaq>, String>((ref, userType) {
      return ref.watch(adminSupportRepositoryProvider).watchFaqs(userType);
    });
