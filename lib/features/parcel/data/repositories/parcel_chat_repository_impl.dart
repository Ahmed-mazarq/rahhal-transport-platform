import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/parcel_chat_repository.dart';
import '../../../trips/domain/models/chat_message.dart';

class ParcelChatRepositoryImpl implements ParcelChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ChatMessage>> watchParcelChatMessages(String parcelId) {
    return _firestore
        .collection('parcel_chats')
        .doc(parcelId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data()..['id'] = doc.id))
              .toList();
        });
  }

  @override
  Future<void> sendParcelMessage({
    required String parcelId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
  }) async {
    final docRef = _firestore
        .collection('parcel_chats')
        .doc(parcelId)
        .collection('messages')
        .doc();

    final message = ChatMessage(
      id: docRef.id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      mimeType: mimeType,
    );

    await docRef.set(message.toJson());
  }

  @override
  Future<void> markMessagesAsRead(String parcelId, String userId) async {
    final unreadMessages = await _firestore
        .collection('parcel_chats')
        .doc(parcelId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    if (unreadMessages.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
