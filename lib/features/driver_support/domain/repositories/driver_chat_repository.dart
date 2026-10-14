import '../models/driver_conversation.dart';
import '../models/driver_message.dart';

abstract class DriverChatRepository {
  /// Start a new conversation or get existing open conversation
  Future<DriverConversation> getOrCreateConversation(String driverId);

  /// Watch current active conversation
  Stream<DriverConversation?> watchActiveConversation(String driverId);

  /// Watch messages in a specific conversation
  Stream<List<DriverMessage>> watchMessages(String conversationId);

  /// Send a message to a conversation
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
  });

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId);

  /// Get unread messages count
  Future<int> getUnreadMessagesCount(String conversationId);

  /// Get conversation by ID
  Future<DriverConversation?> getConversationById(String conversationId);

  /// Create a conversation linked to a specific ticket
  Future<DriverConversation> createConversationForTicket(
    String driverId,
    String ticketId,
  );

  /// Create a conversation linked to a specific report
  Future<DriverConversation> createConversationForReport(
    String driverId,
    String reportId,
  );

  /// Upload support attachment
  Future<String> uploadAttachment(dynamic file, String basePath);
}
