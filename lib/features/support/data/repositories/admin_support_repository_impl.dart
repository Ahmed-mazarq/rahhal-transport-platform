import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../common/utils/exception_handler.dart';
import '../../domain/models/support_conversation.dart';
import '../../domain/models/support_ticket.dart';
import '../../domain/models/support_report.dart';
import '../../domain/repositories/admin_support_repository.dart';

import '../../domain/models/support_faq.dart';

class AdminSupportRepositoryImpl implements AdminSupportRepository {
  final FirebaseFirestore _firestore;

  AdminSupportRepositoryImpl(this._firestore);

  @override
  Stream<Map<String, int>> watchDashboardStats() async* {
    final Map<String, int> stats = {
      'openConversations': 0,
      'newConversations': 0,
      'waitingForReply': 0,
      'urgentChats': 0,
      'reports': 0,
      'tickets': 0,
      'unreadMessages': 0,
      'closedConversations': 0,
    };

    try {
      final prefixes = ['passenger', 'driver', 'company'];

      for (final prefix in prefixes) {
        // Conversations
        final convColl = _firestore.collection(
          '${prefix}_support_conversations',
        );

        final openSnap = await convColl
            .where('status', isEqualTo: 'open')
            .count()
            .get();
        stats['openConversations'] =
            (stats['openConversations'] ?? 0) + (openSnap.count ?? 0);

        final waitingSnap = await convColl
            .where('status', isEqualTo: 'waiting')
            .count()
            .get();
        stats['waitingForReply'] =
            (stats['waitingForReply'] ?? 0) + (waitingSnap.count ?? 0);

        final closedSnap = await convColl
            .where('status', isEqualTo: 'closed')
            .count()
            .get();
        stats['closedConversations'] =
            (stats['closedConversations'] ?? 0) + (closedSnap.count ?? 0);

        final urgentSnap = await convColl
            .where('priority', isEqualTo: 'high')
            .count()
            .get();
        final urgentSnap2 = await convColl
            .where('priority', isEqualTo: 'urgent')
            .where('status', isEqualTo: 'open')
            .count()
            .get();
        stats['urgentChats'] =
            (stats['urgentChats'] ?? 0) +
            (urgentSnap.count ?? 0) +
            (urgentSnap2.count ?? 0);

        final newSnap = await convColl
            .where('status', isEqualTo: 'pending')
            .count()
            .get();
        stats['newConversations'] =
            (stats['newConversations'] ?? 0) + (newSnap.count ?? 0);

        // Tickets
        final ticketColl = _firestore.collection('${prefix}_support_tickets');
        final ticketSnap = await ticketColl.count().get();
        stats['tickets'] = (stats['tickets'] ?? 0) + (ticketSnap.count ?? 0);

        // Reports
        final reportColl = _firestore.collection('${prefix}_support_reports');
        final reportSnap = await reportColl
            .where('status', isEqualTo: 'open')
            .count()
            .get();
        stats['reports'] = (stats['reports'] ?? 0) + (reportSnap.count ?? 0);
      }

      yield stats;
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      yield stats; // yield default on error
    }
  }

  Stream<List<T>> _combineStreams<T>(List<Stream<List<T>>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;
    return Rx.combineLatestList(streams).map((listOfLists) {
      final combined = listOfLists.expand((element) => element).toList();
      return combined;
    });
  }

  @override
  Stream<List<SupportConversation>> watchConversations({
    String? userType,
    String? status,
    String? priority,
  }) {
    final prefixes = ['passenger', 'driver', 'company'];
    final streams = <Stream<List<SupportConversation>>>[];

    for (final prefix in prefixes) {
      if (userType != null && userType.isNotEmpty && userType != prefix) {
        continue;
      }

      Query query = _firestore.collection('${prefix}_support_conversations');

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      if (priority != null && priority.isNotEmpty) {
        query = query.where('priority', isEqualTo: priority);
      }

      // Local sort avoids composite index requirements
      // query = query.orderBy('updatedAt', descending: true);

      streams.add(
        query
            .snapshots()
            .map((snapshot) {
              final list = <SupportConversation>[];
              for (final doc in snapshot.docs) {
                try {
                  final data = Map<String, dynamic>.from(
                    doc.data() as Map<String, dynamic>,
                  );
                  data['prefix'] = prefix;
                  list.add(SupportConversation.fromJson(data, doc.id));
                } catch (e) {
                  debugPrint(
                    'Failed to parse SupportConversation: ${doc.id} - $e',
                  );
                }
              }
              return list;
            })
            .onErrorReturn([]),
      );
    }

    return _combineStreams(streams).map((list) {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Stream<List<SupportTicket>> watchTickets({
    String? userType,
    String? status,
    String? priority,
  }) {
    final prefixes = ['passenger', 'driver', 'company'];
    final streams = <Stream<List<SupportTicket>>>[];

    for (final prefix in prefixes) {
      if (userType != null && userType.isNotEmpty && userType != prefix) {
        continue;
      }

      Query query = _firestore.collection('${prefix}_support_tickets');

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      if (priority != null && priority.isNotEmpty) {
        query = query.where('priority', isEqualTo: priority);
      }

      // Local sort avoids composite index requirements
      // query = query.orderBy('createdAt', descending: true);

      streams.add(
        query
            .snapshots()
            .map((snapshot) {
              final list = <SupportTicket>[];
              for (final doc in snapshot.docs) {
                try {
                  final data = Map<String, dynamic>.from(
                    doc.data() as Map<String, dynamic>,
                  );
                  data['prefix'] = prefix;
                  list.add(SupportTicket.fromJson(data, doc.id));
                } catch (e) {
                  debugPrint('Failed to parse SupportTicket: ${doc.id} - $e');
                }
              }
              return list;
            })
            .onErrorReturn([]),
      );
    }

    return _combineStreams(streams).map((list) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<SupportReport>> watchReports({
    String? reporterType,
    String? status,
  }) {
    final prefixes = ['passenger', 'driver', 'company'];
    final streams = <Stream<List<SupportReport>>>[];

    for (final prefix in prefixes) {
      if (reporterType != null &&
          reporterType.isNotEmpty &&
          reporterType != prefix) {
        continue;
      }

      Query query = _firestore.collection('${prefix}_support_reports');

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      // Local sort avoids composite index requirements
      // query = query.orderBy('createdAt', descending: true);

      streams.add(
        query
            .snapshots()
            .map((snapshot) {
              final list = <SupportReport>[];
              for (final doc in snapshot.docs) {
                try {
                  list.add(
                    SupportReport.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  );
                } catch (e) {
                  debugPrint('Failed to parse SupportReport: ${doc.id} - $e');
                }
              }
              return list;
            })
            .onErrorReturn([]),
      );
    }

    return _combineStreams(streams).map((list) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Helper method to find a document reference across all prefixes
  Future<DocumentReference?> _findDocumentAcrossPrefixes(
    String collectionSuffix,
    String docId,
  ) async {
    final prefixes = ['passenger', 'driver', 'company'];
    for (final prefix in prefixes) {
      final docRef = _firestore
          .collection('${prefix}_$collectionSuffix')
          .doc(docId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return docRef;
      }
    }
    return null;
  }

  @override
  Future<void> updateConversationStatus(
    String conversationId,
    String status, {
    String? adminId,
  }) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_conversations',
        conversationId,
      );
      if (docRef != null) {
        final updates = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (status == 'closed') {
          updates['closedAt'] = FieldValue.serverTimestamp();
          if (adminId != null) {
            updates['closedBy'] = adminId;
          }
        }

        await docRef.update(updates);
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> updateConversationPriority(
    String conversationId,
    String priority,
  ) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_conversations',
        conversationId,
      );
      if (docRef != null) {
        await docRef.update({
          'priority': priority,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> assignConversation(
    String conversationId,
    String employeeId,
  ) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_conversations',
        conversationId,
      );
      if (docRef != null) {
        await docRef.update({
          'assignedTo': employeeId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> transferConversation(
    String conversationId,
    String department,
    String priority,
  ) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_conversations',
        conversationId,
      );
      if (docRef != null) {
        await docRef.update({
          'department': department,
          'priority': priority,
          'status': 'open', // Re-open the conversation upon transfer
          'assignedTo':
              null, // Clear assignment when transferring to a department
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_tickets',
        ticketId,
      );
      if (docRef != null) {
        await docRef.update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> updateTicketPriority(String ticketId, String priority) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_tickets',
        ticketId,
      );
      if (docRef != null) {
        await docRef.update({
          'priority': priority,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> assignTicket(String ticketId, String employeeId) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_tickets',
        ticketId,
      );
      if (docRef != null) {
        await docRef.update({
          'assignedAdminId': employeeId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      final docRef = await _findDocumentAcrossPrefixes(
        'support_reports',
        reportId,
      );
      if (docRef != null) {
        await docRef.update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  // --- Contacts ---

  @override
  Stream<Map<String, dynamic>?> watchContact(String userType) {
    return _firestore
        .collection('${userType}_support_contact')
        .doc('main')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  @override
  Future<void> updateContact(String userType, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('${userType}_support_contact')
          .doc('main')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  // --- FAQs ---

  @override
  Stream<List<SupportFaq>> watchFaqs(String userType) {
    return _firestore
        .collection('${userType}_support_faq')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                try {
                  return SupportFaq.fromJson(doc.data(), doc.id);
                } catch (e) {
                  return null;
                }
              })
              .whereType<SupportFaq>()
              .toList(),
        );
  }

  @override
  Future<void> addFaq(String userType, SupportFaq faq) async {
    try {
      final docRef = _firestore.collection('${userType}_support_faq').doc();
      final data = faq.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(data);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> updateFaq(String userType, SupportFaq faq) async {
    try {
      final data = faq.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('${userType}_support_faq')
          .doc(faq.id)
          .update(data);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> deleteFaq(String userType, String faqId) async {
    try {
      await _firestore
          .collection('${userType}_support_faq')
          .doc(faqId)
          .delete();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
