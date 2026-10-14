import '../models/chat_message.dart';

abstract class BookingChatRepository {
  Stream<List<ChatMessage>> watchBookingChatMessages(String bookingId);
  Future<void> sendBookingMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
  });
  Future<void> markMessagesAsRead(String bookingId, String userId);
}
