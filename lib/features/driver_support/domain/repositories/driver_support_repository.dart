import 'package:file_picker/file_picker.dart';

import '../models/driver_ticket.dart';
import '../models/driver_report.dart';
import '../models/driver_faq.dart';

abstract class DriverSupportRepository {
  /// Create a new support ticket
  Future<void> createTicket(DriverTicket ticket);

  /// Watch driver's tickets
  Stream<List<DriverTicket>> watchMyTickets(String driverId);

  /// Get ticket by ID
  Future<DriverTicket?> getTicketById(String ticketId);

  /// Ensure ticket has conversation and return updated ticket
  Future<DriverTicket> ensureTicketConversation(DriverTicket ticket);

  /// Create a report
  Future<void> submitReport(DriverReport report);

  /// Watch driver's reports
  Stream<List<DriverReport>> watchMyReports(String driverId);

  // Contacts
  Stream<Map<String, dynamic>?> watchContact();

  /// Watch FAQs
  Stream<List<DriverFaq>> watchFaqs();

  /// Seed FAQs if empty
  Future<void> seedFaqsIfEmpty();

  /// Upload attachment for ticket/report
  Future<String> uploadAttachment(PlatformFile file, String path);
}
