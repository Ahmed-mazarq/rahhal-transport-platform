import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';

import '../../../common/utils/exception_handler.dart';
import '../../domain/models/driver_conversation.dart';
import '../../domain/models/driver_message.dart';
import '../../domain/repositories/driver_chat_repository.dart';

class DriverChatRepositoryImpl implements DriverChatRepository {
  final FirebaseFirestore _firestore;

  DriverChatRepositoryImpl(this._firestore);

  @override
  Future<DriverConversation> getOrCreateConversation(String driverId) async {
    try {
      debugPrint('--- QUERY: driver_support_conversations ---');
      debugPrint('where: participantIds arrayContains $driverId');
      debugPrint('where: status isEqualTo open');
      debugPrint('limit: 1');
      final querySnapshot = await _firestore
          .collection('driver_support_conversations')
          .where('participantIds', arrayContains: driverId)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return DriverConversation.fromJson(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }

      final docRef = _firestore
          .collection('driver_support_conversations')
          .doc();
      final conversation = DriverConversation(
        conversationId: docRef.id,
        participantIds: [driverId],
        status: 'open',
        priority: 'low',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await docRef.set(conversation.toJson());
      return conversation;
    } catch (e, st) {
      if (e is FirebaseException) {
        debugPrint('--- FIRESTORE ERROR in getOrCreateConversation ---');
        debugPrint('Code: ${e.code}');
        debugPrint('Message: ${e.message}');
        debugPrint(e.stackTrace?.toString() ?? st.toString());
      }
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Stream<DriverConversation?> watchActiveConversation(String driverId) {
    debugPrint('--- WATCH QUERY: driver_support_conversations ---');
    debugPrint('where: participantIds arrayContains $driverId');
    debugPrint('where: status isEqualTo open');
    debugPrint('limit: 1');
    return _firestore
        .collection('driver_support_conversations')
        .where('participantIds', arrayContains: driverId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return DriverConversation.fromJson(
              snapshot.docs.first.data(),
              snapshot.docs.first.id,
            );
          }
          return null;
        })
        .handleError((error, st) {
          if (error is FirebaseException) {
            debugPrint('--- FIRESTORE ERROR in watchActiveConversation ---');
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');
            debugPrint(error.stackTrace?.toString() ?? st.toString());
          }
          throw ExceptionHandler.handle(error);
        });
  }

  @override
  Stream<List<DriverMessage>> watchMessages(String conversationId) {
    debugPrint('--- WATCH QUERY: driver_support_messages ---');
    debugPrint('where: conversationId isEqualTo $conversationId');
    debugPrint('orderBy: createdAt descending: true');
    return _firestore
        .collection('driver_support_messages')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => DriverMessage.fromJson(doc.data(), doc.id))
              .toList();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        })
        .handleError((error, st) {
          if (error is FirebaseException) {
            debugPrint('--- FIRESTORE ERROR in watchMessages ---');
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');
            debugPrint(error.stackTrace?.toString() ?? st.toString());
          }
          throw ExceptionHandler.handle(error);
        });
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    String driverId,
    String text, {
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
    String? thumbnail,
    int? duration,
  }) async {
    try {
      final convDoc = await _firestore
          .collection('driver_support_conversations')
          .doc(conversationId)
          .get();
      if (convDoc.exists && convDoc.data()?['status'] == 'closed') {
        throw Exception('Cannot send message. Conversation is closed.');
      }

      final batch = _firestore.batch();

      final messageRef = _firestore.collection('driver_support_messages').doc();
      final message = DriverMessage(
        messageId: messageRef.id,
        conversationId: conversationId,
        senderId: driverId,
        senderRole: 'driver',
        message: text,
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

      final conversationRef = _firestore
          .collection('driver_support_conversations')
          .doc(conversationId);
      batch.update(conversationRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      await batch.commit();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      debugPrint('--- QUERY: driver_support_messages (markRead) ---');
      debugPrint('where: conversationId isEqualTo $conversationId');
      debugPrint('where: senderRole isEqualTo admin');
      debugPrint('where: isRead isEqualTo false');
      final unreadMsgs = await _firestore
          .collection('driver_support_messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('senderRole', isEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMsgs.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadMsgs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e, st) {
      if (e is FirebaseException) {
        debugPrint('--- FIRESTORE ERROR in markMessagesAsRead ---');
        debugPrint('Code: ${e.code}');
        debugPrint('Message: ${e.message}');
        debugPrint(e.stackTrace?.toString() ?? st.toString());
      }
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<int> getUnreadMessagesCount(String conversationId) async {
    try {
      final msgs = await _firestore
          .collection('driver_support_messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('senderRole', isEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();
      return msgs.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Future<DriverConversation?> getConversationById(String conversationId) async {
    try {
      final docSnapshot = await _firestore
          .collection('driver_support_conversations')
          .doc(conversationId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return DriverConversation.fromJson(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<DriverConversation> createConversationForTicket(
    String driverId,
    String ticketId,
  ) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore
          .collection('driver_support_conversations')
          .doc();
      final conversation = DriverConversation(
        conversationId: docRef.id,
        ticketId: ticketId,
        participantIds: [driverId],
        status: 'open',
        priority: 'low',
        conversationType: 'ticket',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      batch.set(docRef, conversation.toJson());

      final ticketRef = _firestore
          .collection('driver_support_tickets')
          .doc(ticketId);
      batch.update(ticketRef, {'conversationId': docRef.id});

      await batch.commit();
      return conversation;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<DriverConversation> createConversationForReport(
    String driverId,
    String reportId,
  ) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore
          .collection('driver_support_conversations')
          .doc();
      final conversation = DriverConversation(
        conversationId: docRef.id,
        reportId: reportId,
        participantIds: [driverId],
        status: 'open',
        priority: 'low',
        conversationType: 'report',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      batch.set(docRef, conversation.toJson());

      // assuming driver reports are saved in support_reports, but maybe driver_support_reports
      // Actually we just return the conversation.
      await batch.commit();
      return conversation;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<String> uploadAttachment(dynamic file, String basePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final storageService = SupabaseStorageService();
      final conversationId = basePath.split('/').last;

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
        'driver',
        user.uid,
        conversationId,
        xfile,
      );
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}
