import 'package:rahal/features/trips/domain/models/chat_message.dart';

abstract class ParcelChatRepository {
  Stream<List<ChatMessage>> watchParcelChatMessages(String parcelId);
  Future<void> sendParcelMessage({
    required String parcelId,
    required String senderId,
    required String senderName,
    required String content,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
  });
  Future<void> markMessagesAsRead(String parcelId, String userId);
}
