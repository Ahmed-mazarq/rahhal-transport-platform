import '../models/support_faq.dart';
import '../models/support_setting.dart';
import '../models/support_ticket.dart';
import '../models/support_report.dart';

abstract class SupportRepository {
  // Tickets
  Future<void> createTicket(SupportTicket ticket);
  Stream<List<SupportTicket>> watchMyTickets(String userId);

  // Reports
  Future<void> submitReport(SupportReport report);
  Stream<List<SupportReport>> watchMyReports(String userId);

  // FAQ
  Future<List<SupportFaq>> getFaqs();
  Stream<List<SupportFaq>> watchFaqs();

  // Contacts
  Stream<Map<String, dynamic>?> watchContact();

  // Settings
  Future<SupportSetting> getSettings();
  Stream<SupportSetting> watchSettings();

  // Storage
  Future<String> uploadAttachment(dynamic file, String path);
}
