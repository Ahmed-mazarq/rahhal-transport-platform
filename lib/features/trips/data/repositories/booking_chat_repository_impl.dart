import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/booking_chat_repository.dart';

class BookingChatRepositoryImpl implements BookingChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ChatMessage>> watchBookingChatMessages(String bookingId) {
    return _firestore
        .collection('booking_chats')
        .doc(bookingId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data()))
              .toList();
        });
  }

  @override
  Future<void> sendBookingMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
  }) async {
    final docRef = _firestore
        .collection('booking_chats')
        .doc(bookingId)
        .collection('messages')
        .doc();

    final message = ChatMessage(
      id: docRef.id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      mimeType: mimeType,
    );

    await docRef.set(message.toJson());
  }

  @override
  Future<void> markMessagesAsRead(String bookingId, String userId) async {
    final unreadMessages = await _firestore
        .collection('booking_chats')
        .doc(bookingId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    int count = 0;
    for (var doc in unreadMessages.docs) {
      if (doc.data()['senderId'] != userId) {
        batch.update(doc.reference, {'isRead': true});
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}
