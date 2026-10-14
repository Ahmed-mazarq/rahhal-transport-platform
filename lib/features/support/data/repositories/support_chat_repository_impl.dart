import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../../domain/repositories/support_chat_repository.dart';
import '../../domain/models/support_message.dart';
import '../../domain/models/support_conversation.dart';
import '../../../../core/services/notification_service.dart';

class SupportChatRepositoryImpl implements SupportChatRepository {
  final FirebaseFirestore firestore;
  final String collectionPrefix;

  SupportChatRepositoryImpl(this.firestore, {required this.collectionPrefix});

  String get _collectionName => '${collectionPrefix}_support_messages';
  String get _convCollectionName => '${collectionPrefix}_support_conversations';

  @override
  Future<SupportConversation?> getConversationById(String id) async {
    final doc = await firestore.collection(_convCollectionName).doc(id).get();
    if (doc.exists) {
      final data = Map<String, dynamic>.from(doc.data()!);
      data['prefix'] = collectionPrefix;
      return SupportConversation.fromJson(data, doc.id);
    }
    return null;
  }

  @override
  Future<SupportConversation> getOrCreateConversation(String userId) async {
    final querySnapshot = await firestore
        .collection(_convCollectionName)
        .where('participantIds', arrayContains: userId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['prefix'] = collectionPrefix;
      return SupportConversation.fromJson(data, doc.id);
    }

    final docRef = firestore.collection(_convCollectionName).doc();
    final conversation = SupportConversation(
      conversationId: docRef.id,
      participantIds: [userId],
      status: 'open',
      priority: 'low',
      userType: collectionPrefix,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await docRef.set(
      conversation.toJson()..addAll({'userType': collectionPrefix}),
    );
    return conversation;
  }

  @override
  Future<SupportConversation> createConversationForTicket(
    String userId,
    String ticketId,
  ) async {
    final querySnapshot = await firestore
        .collection(_convCollectionName)
        .where('ticketId', isEqualTo: ticketId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['prefix'] = collectionPrefix;
      return SupportConversation.fromJson(data, doc.id);
    }

    final docRef = firestore.collection(_convCollectionName).doc();
    final conversation = SupportConversation(
      conversationId: docRef.id,
      participantIds: [userId],
      status: 'open',
      priority: 'low',
      userType: collectionPrefix,
      conversationType: 'ticket',
      ticketId: ticketId,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await docRef.set(
      conversation.toJson()..addAll({'userType': collectionPrefix}),
    );
    return conversation;
  }

  @override
  Future<SupportConversation> createConversationForReport(
    String userId,
    String reportId,
  ) async {
    final querySnapshot = await firestore
        .collection(_convCollectionName)
        .where('reportId', isEqualTo: reportId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['prefix'] = collectionPrefix;
      return SupportConversation.fromJson(data, doc.id);
    }

    final docRef = firestore.collection(_convCollectionName).doc();
    final conversation = SupportConversation(
      conversationId: docRef.id,
      participantIds: [userId],
      status: 'open',
      priority: 'low',
      userType: collectionPrefix,
      conversationType: 'report',
      reportId: reportId,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await docRef.set(
      conversation.toJson()..addAll({'userType': collectionPrefix}),
    );
    return conversation;
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String conversationId) {
    return firestore
        .collection(_collectionName)
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => SupportMessage.fromJson(doc.data(), doc.id))
              .toList();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        });
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String userId,
    String text, {
    String? senderType,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
    String? thumbnail,
    int? duration,
  }) async {
    final convRef = firestore
        .collection('${collectionPrefix}_support_conversations')
        .doc(conversationId);
    final convDoc = await convRef.get();
    if (convDoc.exists && convDoc.data()?['status'] == 'closed') {
      throw Exception('Cannot send message. Conversation is closed.');
    }

    final batch = firestore.batch();

    final messageRef = firestore.collection(_collectionName).doc();
    final message = SupportMessage(
      messageId: messageRef.id,
      conversationId: conversationId,
      senderId: userId,
      senderType: senderType ?? collectionPrefix,
      text: text,
      createdAt: DateTime.now(),
      isRead: false,
      isDelivered: false,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      mimeType: mimeType,
      thumbnail: thumbnail,
      duration: duration,
    );

    batch.set(messageRef, message.toJson());

    batch.update(convRef, {
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'status': 'open',
    });

    await batch.commit();

    if (senderType == 'admin') {
      final participantIds = List<String>.from(
        convDoc.data()?['participantIds'] ?? [],
      );
      final targetUserId = participantIds.isNotEmpty
          ? participantIds.first
          : '';
      if (targetUserId.isNotEmpty) {
        await SystemNotificationService.sendNotification(
          title: 'رسالة جديدة من الدعم الفني',
          body: text,
          targetUserId: targetUserId,
          category: 'support',
          targetRole: collectionPrefix,
        );
      }
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    final unreadQuery = await firestore
        .collection(_collectionName)
        .where('conversationId', isEqualTo: conversationId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadQuery.docs.isEmpty) return;

    final batch = firestore.batch();
    for (final doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<String> uploadAttachment(dynamic file, String basePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final storageService = SupabaseStorageService();
      // We ignore basePath to enforce the strict RLS bucket policy: support/{userId}/...
      // The basePath usually contains the conversationId at the end, so we extract it:
      final conversationId = basePath.split('/').last;

      // Convert PlatformFile to XFile robustly since SupabaseStorageService expects XFile
      final platformFile = file as PlatformFile;
      XFile xfile;
      if (platformFile.bytes != null && platformFile.bytes!.isNotEmpty) {
        xfile = XFile.fromData(platformFile.bytes!, name: platformFile.name);
      } else if (platformFile.path != null && platformFile.path!.isNotEmpty) {
        xfile = XFile(platformFile.path!, name: platformFile.name);
      } else {
        throw Exception('Invalid file structure: no bytes and no path');
      }

      return await storageService.uploadSupportAttachment(
        collectionPrefix,
        user.uid,
        conversationId,
        xfile,
      );
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}
