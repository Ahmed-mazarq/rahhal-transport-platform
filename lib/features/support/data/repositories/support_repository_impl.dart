import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/support_repository.dart';
import '../../domain/models/support_faq.dart';
import '../../domain/models/support_setting.dart';
import '../../domain/models/support_ticket.dart';
import '../../domain/models/support_report.dart';
import '../../domain/models/support_conversation.dart';
import '../../../common/utils/exception_handler.dart';
import '../../../../core/services/notification_service.dart';

class SupportRepositoryImpl implements SupportRepository {
  final FirebaseFirestore _firestore;
  final String collectionPrefix;

  SupportRepositoryImpl(this._firestore, {required this.collectionPrefix});

  @override
  Future<void> createTicket(SupportTicket ticket) async {
    try {
      final batch = _firestore.batch();

      final ticketRef = _firestore
          .collection('${collectionPrefix}_support_tickets')
          .doc();
      final conversationRef = _firestore
          .collection('${collectionPrefix}_support_conversations')
          .doc();

      final newTicket = SupportTicket(
        ticketId: ticketRef.id,
        title: ticket.title,
        description: ticket.description,
        status: ticket.status,
        priority: ticket.priority,
        userId: ticket.userId,
        conversationId: conversationRef.id,
        category: ticket.category,
        userType: collectionPrefix,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newConversation = SupportConversation(
        conversationId: conversationRef.id,
        ticketId: ticketRef.id,
        participantIds: [ticket.userId],
        status: 'open',
        priority: ticket.priority,
        userType: collectionPrefix,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      batch.set(ticketRef, newTicket.toJson());
      batch.set(conversationRef, newConversation.toJson());

      await batch.commit();

      await SystemNotificationService.sendNotification(
        title: 'تم استلام تذكرتك',
        body:
            'تم استلام تذكرة الدعم الفني الخاصة بك بنجاح، سيتم الرد عليك قريباً.',
        targetUserId: ticket.userId,
        category: 'support',
        targetRole: collectionPrefix,
      );
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Stream<List<SupportTicket>> watchMyTickets(String userId) {
    return _firestore
        .collection('${collectionPrefix}_support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs.map((doc) {
            final data = doc.data();
            data['prefix'] = collectionPrefix;
            return SupportTicket.fromJson(data, doc.id);
          }).toList();
          tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return tickets;
        })
        .handleError((error) {
          throw ExceptionHandler.handle(error);
        });
  }

  @override
  Future<void> submitReport(SupportReport report) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore
          .collection('${collectionPrefix}_support_reports')
          .doc();
      final conversationRef = _firestore
          .collection('${collectionPrefix}_support_conversations')
          .doc();

      final newReport = SupportReport(
        id: docRef.id,
        status: report.status,
        reason: report.reason,
        reporterType: collectionPrefix,
        reporterId: report.reporterId,
        reportedId: report.reportedId,
        reportedType: report.reportedType,
        tripId: report.tripId,
        bookingId: report.bookingId,
        companyId: report.companyId,
        driverId: report.driverId,
        description: report.description,
        priority: report.priority,
        attachments: report.attachments,
        conversationId: conversationRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newConversation = SupportConversation(
        conversationId: conversationRef.id,
        reportId: docRef.id,
        conversationType: 'report',
        participantIds: [report.reporterId],
        status: 'open',
        priority: report.priority,
        userType: collectionPrefix,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      batch.set(docRef, newReport.toJson());
      batch.set(conversationRef, newConversation.toJson());

      await batch.commit();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Stream<List<SupportReport>> watchMyReports(String userId) {
    return _firestore
        .collection('${collectionPrefix}_support_reports')
        .where('reporterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs.map((doc) {
            final data = doc.data();
            return SupportReport.fromJson(data, doc.id);
          }).toList();
          reports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return reports;
        })
        .handleError((error) {
          throw ExceptionHandler.handle(error);
        });
  }

  @override
  Future<List<SupportFaq>> getFaqs() async {
    try {
      final snapshot = await _firestore
          .collection('${collectionPrefix}_support_faq')
          .orderBy('order')
          .get();
      return snapshot.docs
          .map((doc) => SupportFaq.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Stream<List<SupportFaq>> watchFaqs() {
    debugPrint('--- WATCH QUERY: ${collectionPrefix}_support_faq ---');
    debugPrint('where: isActive isEqualTo true');
    debugPrint('orderBy: order ASC');
    return _firestore
        .collection('${collectionPrefix}_support_faq')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final faqs = snapshot.docs
              .map((doc) => SupportFaq.fromJson(doc.data(), doc.id))
              .toList();
          faqs.sort((a, b) => a.order.compareTo(b.order));
          return faqs;
        })
        .handleError((error, st) {
          if (error is FirebaseException) {
            debugPrint('--- FIRESTORE ERROR in watchFaqs ---');
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');
            debugPrint(error.stackTrace?.toString() ?? st.toString());
          }
          throw ExceptionHandler.handle(error);
        });
  }

  Future<void> seedFaqsIfEmpty() async {
    try {
      final querySnapshot = await _firestore
          .collection('${collectionPrefix}_support_faq')
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        final batch = _firestore.batch();
        final faqs = [
          {
            'q': 'كيف يمكنني حجز رحلة؟',
            'a':
                'يمكنك حجز رحلة من خلال البحث عن الوجهة المطلوبة واختيار الرحلة المناسبة لك.',
          },
          {
            'q': 'ما هي طرق الدفع المتاحة؟',
            'a':
                'نوفر عدة طرق للدفع منها البطاقات الائتمانية، مدى، Apple Pay والدفع نقداً للسائق.',
          },
          {
            'q': 'كيف يمكنني إلغاء الحجز؟',
            'a':
                'يمكنك إلغاء الحجز من خلال الذهاب إلى قائمة حجوزاتي واختيار الرحلة ثم الضغط على إلغاء.',
          },
          {
            'q': 'هل يمكنني تغيير موعد الرحلة؟',
            'a':
                'يمكنك تغيير الموعد قبل 24 ساعة من موعد انطلاق الرحلة بالتواصل مع الدعم الفني.',
          },
          {
            'q': 'ماذا أفعل إذا تأخر السائق؟',
            'a':
                'في حال تأخر السائق عن الموعد المحدد يمكنك التواصل معه مباشرة أو إبلاغ الدعم الفني للتعويض.',
          },
          {
            'q': 'كيف أقيم السائق بعد الرحلة؟',
            'a':
                'بعد انتهاء الرحلة ستظهر لك شاشة التقييم حيث يمكنك تقييم الخدمة وكتابة ملاحظاتك.',
          },
        ];

        for (int i = 0; i < faqs.length; i++) {
          final docRef = _firestore
              .collection('${collectionPrefix}_support_faq')
              .doc();
          final newFaq = SupportFaq(
            id: docRef.id,
            category: 'عام',
            question: faqs[i]['q']!,
            answer: faqs[i]['a']!,
            order: i,
            isActive: true,
          );
          batch.set(docRef, newFaq.toJson());
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Failed to seed faqs: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchContact() {
    return _firestore
        .collection('${collectionPrefix}_support_contact')
        .doc('settings')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return snapshot.data();
        });
  }

  @override
  Future<SupportSetting> getSettings() async {
    return const SupportSetting(
      id: 'default',
      contactEmail: 'support@rahal.com',
      contactPhone: '+1234567890',
      operatingHours: {},
    );
  }

  @override
  Stream<SupportSetting> watchSettings() {
    return Stream.value(
      const SupportSetting(
        id: 'default',
        contactEmail: 'support@rahal.com',
        contactPhone: '+1234567890',
        operatingHours: {},
      ),
    );
  }

  @override
  Future<String> uploadAttachment(dynamic file, String path) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final storageService = SupabaseStorageService();
      // Using public bucket: support/{userId}/...
      // The path parameter might contain context like 'tickets', but for RLS we need conversationId or ticketId.
      // Assuming path is just an identifier, we append it after user.uid
      final identifier = path.replaceAll('/', '_');

      // Convert PlatformFile to XFile since SupabaseStorageService expects XFile
      final platformFile = file as PlatformFile;
      final xfile = XFile(
        platformFile.path ?? '',
        name: platformFile.name,
        bytes: platformFile.bytes,
      );

      return await storageService.uploadSupportAttachment(
        collectionPrefix,
        user.uid,
        identifier,
        xfile,
      );
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}
