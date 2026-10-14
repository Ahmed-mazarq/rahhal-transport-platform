import '../models/support_message.dart';

import '../models/support_conversation.dart';

abstract class SupportChatRepository {
  Future<SupportConversation?> getConversationById(String id);
  Future<SupportConversation> getOrCreateConversation(String userId);
  Future<SupportConversation> createConversationForTicket(
    String userId,
    String ticketId,
  );
  Future<SupportConversation> createConversationForReport(
    String userId,
    String reportId,
  );
  Stream<List<SupportMessage>> watchMessages(String conversationId);
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
  });
  Future<void> markMessagesAsRead(String conversationId);
  Future<String> uploadAttachment(dynamic file, String basePath);
}
