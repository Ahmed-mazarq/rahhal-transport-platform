import '../models/support_conversation.dart';
import '../models/support_ticket.dart';
import '../models/support_report.dart';
import '../models/support_faq.dart';

abstract class AdminSupportRepository {
  // Dashboard Overviews
  Stream<Map<String, int>> watchDashboardStats();

  // Conversations
  Stream<List<SupportConversation>> watchConversations({
    String? userType,
    String? status,
    String? priority,
  });

  // Tickets

  // Reports

  // Tickets
  Stream<List<SupportTicket>> watchTickets({
    String? userType,
    String? status,
    String? priority,
  });

  // Reports
  Stream<List<SupportReport>> watchReports({
    String? reporterType,
    String? status,
  });

  // Actions
  Future<void> updateConversationStatus(
    String conversationId,
    String status, {
    String? adminId,
  });
  Future<void> updateConversationPriority(
    String conversationId,
    String priority,
  );
  Future<void> assignConversation(String conversationId, String employeeId);
  Future<void> transferConversation(
    String conversationId,
    String department,
    String priority,
  );

  Future<void> updateTicketStatus(String ticketId, String status);
  Future<void> updateTicketPriority(String ticketId, String priority);
  Future<void> assignTicket(String ticketId, String employeeId);
  Future<void> updateReportStatus(String reportId, String status);

  // Contacts
  Stream<Map<String, dynamic>?> watchContact(String userType);
  Future<void> updateContact(String userType, Map<String, dynamic> data);

  // FAQs
  Stream<List<SupportFaq>> watchFaqs(String userType);
  Future<void> addFaq(String userType, SupportFaq faq);
  Future<void> updateFaq(String userType, SupportFaq faq);
  Future<void> deleteFaq(String userType, String faqId);
}
