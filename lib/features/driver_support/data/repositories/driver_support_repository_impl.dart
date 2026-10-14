import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import 'package:file_picker/file_picker.dart';

import '../../../common/utils/exception_handler.dart';
import '../../domain/models/driver_ticket.dart';
import '../../domain/models/driver_report.dart';
import '../../domain/models/driver_faq.dart';
import '../../domain/models/driver_conversation.dart';
import '../../domain/repositories/driver_support_repository.dart';

class DriverSupportRepositoryImpl implements DriverSupportRepository {
  final FirebaseFirestore _firestore;

  DriverSupportRepositoryImpl(this._firestore);

  @override
  Future<void> createTicket(DriverTicket ticket) async {
    try {
      final batch = _firestore.batch();

      final ticketRef = _firestore.collection('driver_support_tickets').doc();
      final conversationRef = _firestore
          .collection('driver_support_conversations')
          .doc();

      final newTicket = DriverTicket(
        ticketId: ticketRef.id,
        title: ticket.title,
        description: ticket.description,
        status: ticket.status,
        priority: ticket.priority,
        category: ticket.category,
        driverId: ticket.driverId,
        conversationId: conversationRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newConversation = DriverConversation(
        conversationId: conversationRef.id,
        ticketId: ticketRef.id,
        participantIds: [ticket.driverId],
        status: 'open',
        priority: ticket.priority,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      batch.set(ticketRef, newTicket.toJson());
      batch.set(conversationRef, newConversation.toJson());

      await batch.commit();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Stream<List<DriverTicket>> watchMyTickets(String driverId) {
    debugPrint('--- WATCH QUERY: driver_support_tickets ---');
    debugPrint('where: Filter.or(driverId == $driverId, userId == $driverId)');
    return _firestore
        .collection('driver_support_tickets')
        .where(
          Filter.or(
            Filter('driverId', isEqualTo: driverId),
            Filter('userId', isEqualTo: driverId),
          ),
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final tickets = <DriverTicket>[];
          for (var doc in snapshot.docs) {
            var ticket = DriverTicket.fromJson(doc.data(), doc.id);
            if (ticket.conversationId == null) {
              ticket = await ensureTicketConversation(ticket);
            }
            tickets.add(ticket);
          }
          tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return tickets;
        })
        .handleError((error, st) {
          if (error is FirebaseException) {
            debugPrint('--- FIRESTORE ERROR in watchMyTickets ---');
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');
            debugPrint(error.stackTrace?.toString() ?? st.toString());
          }
          throw ExceptionHandler.handle(error);
        });
  }

  @override
  Future<DriverTicket?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore
          .collection('driver_support_tickets')
          .doc(ticketId)
          .get();
      if (doc.exists) {
        return DriverTicket.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<DriverTicket> ensureTicketConversation(DriverTicket ticket) async {
    if (ticket.conversationId != null) return ticket;

    try {
      final docRef = _firestore
          .collection('driver_support_conversations')
          .doc();
      final conversation = DriverConversation(
        conversationId: docRef.id,
        ticketId: ticket.ticketId,
        participantIds: [ticket.driverId],
        status: ticket.status,
        priority: ticket.priority,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      batch.set(docRef, conversation.toJson());
      batch.update(
        _firestore.collection('driver_support_tickets').doc(ticket.ticketId),
        {'conversationId': docRef.id},
      );
      await batch.commit();

      return DriverTicket(
        ticketId: ticket.ticketId,
        title: ticket.title,
        description: ticket.description,
        status: ticket.status,
        priority: ticket.priority,
        category: ticket.category,
        driverId: ticket.driverId,
        conversationId: docRef.id,
        createdAt: ticket.createdAt,
        updatedAt: ticket.updatedAt,
      );
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<void> submitReport(DriverReport report) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection('driver_support_reports').doc();
      final conversationRef = _firestore
          .collection('driver_support_conversations')
          .doc();

      final newReport = DriverReport(
        reportId: docRef.id,
        category: report.category,
        subCategory: report.subCategory,
        description: report.description,
        images: report.images,
        reporterId: report.reporterId,
        reportedId: report.reportedId,
        reportedType: report.reportedType,
        tripId: report.tripId,
        bookingId: report.bookingId,
        companyId: report.companyId,
        status: report.status,
        priority: report.priority,
        conversationId: conversationRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newConversation = DriverConversation(
        conversationId: conversationRef.id,
        reportId: docRef.id,
        conversationType: 'report',
        participantIds: [report.reporterId],
        status: 'open',
        priority: report.priority,
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
  Stream<List<DriverReport>> watchMyReports(String driverId) {
    debugPrint('--- WATCH QUERY: driver_support_reports ---');
    debugPrint('where: reporterId isEqualTo $driverId');
    return _firestore
        .collection('driver_support_reports')
        .where('reporterId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map((doc) => DriverReport.fromJson(doc.data(), doc.id))
              .toList();
          reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reports;
        })
        .handleError((error, st) {
          if (error is FirebaseException) {
            debugPrint('--- FIRESTORE ERROR in watchMyReports ---');
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');
            debugPrint(error.stackTrace?.toString() ?? st.toString());
          }
          throw ExceptionHandler.handle(error);
        });
  }

  @override
  Stream<Map<String, dynamic>?> watchContact() {
    return _firestore
        .collection('driver_support_contact')
        .doc('settings')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return snapshot.data();
        });
  }

  @override
  Stream<List<DriverFaq>> watchFaqs() {
    debugPrint('--- WATCH QUERY: driver_support_faq ---');
    debugPrint('where: isActive isEqualTo true');
    debugPrint('orderBy: order ASC');
    return _firestore
        .collection('driver_support_faq')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final faqs = snapshot.docs
              .map((doc) => DriverFaq.fromJson(doc.data(), doc.id))
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

  @override
  Future<void> seedFaqsIfEmpty() async {
    try {
      final querySnapshot = await _firestore
          .collection('driver_support_faq')
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        final batch = _firestore.batch();
        final faqs = [
          {
            'title': 'كيف أنشر رحلة جديدة؟',
            'answer':
                'يمكنك نشر رحلة جديدة من خلال الذهاب إلى قسم الرحلات والضغط على زر إضافة رحلة وتعبئة التفاصيل المطلوبة.',
          },
          {
            'title': 'كيف أضيف مركبة جديدة؟',
            'answer':
                'من خلال قسم المركبات في التطبيق، اضغط على إضافة مركبة وأدخل بيانات الاستمارة والتأمين.',
          },
          {
            'title': 'لماذا تم رفض الوثائق؟',
            'answer':
                'قد ترفض الوثائق إذا كانت غير واضحة أو منتهية الصلاحية. تأكد من وضوح الصورة وتاريخ الصلاحية.',
          },
          {
            'title': 'كيف أرفع الوثائق مرة أخرى؟',
            'answer':
                'يمكنك إعادة رفع الوثائق من صفحة حسابك الشخصي أو قسم الوثائق.',
          },
          {
            'title': 'كيف أعدل بيانات المركبة؟',
            'answer':
                'اذهب إلى قائمة مركباتك واختر المركبة التي تود تعديلها واضغط على أيقونة التعديل.',
          },
          {
            'title': 'كيف أغير رقم الهاتف؟',
            'answer':
                'لتغيير رقم الهاتف، يجب التواصل مع الدعم الفني لضمان أمان حسابك.',
          },
          {
            'title': 'كيف أضيف حسابًا بنكيًا؟',
            'answer':
                'من قسم المحفظة، اختر الحسابات البنكية واضغط على إضافة حساب جديد وأدخل رقم الآيبان.',
          },
          {
            'title': 'كيف أستقبل أرباحي؟',
            'answer':
                'يتم تحويل الأرباح أسبوعياً أو عند طلب سحب الرصيد إلى حسابك البنكي المسجل.',
          },
          {
            'title': 'كيف أتواصل مع الدعم؟',
            'answer':
                'يمكنك إنشاء تذكرة دعم أو الدخول في المحادثة الفورية مع فريق الدعم من هذه الشاشة.',
          },
          {
            'title': 'كيف أبلغ عن راكب؟',
            'answer':
                'من خلال قسم البلاغات، يمكنك إنشاء بلاغ جديد واختيار مشكلة مع راكب وتحديد الرحلة.',
          },
          {
            'title': 'كيف أستعيد كلمة المرور؟',
            'answer':
                'من شاشة تسجيل الدخول اضغط على "نسيت كلمة المرور" واتبع التعليمات المرسلة لجوالك.',
          },
          {
            'title': 'كيف أعدل موعد الرحلة؟',
            'answer':
                'اذهب إلى تفاصيل الرحلة واضغط على تعديل الموعد. سيتم إشعار الركاب بتغير الموعد.',
          },
          {
            'title': 'لماذا لا تظهر رحلاتي للمسافرين؟',
            'answer':
                'تأكد من تنشيط الرحلة وأن وثائقك وحالة حسابك فعالة وغير معلقة.',
          },
          {
            'title': 'كيف أسترجع حسابي؟',
            'answer':
                'في حال تم إيقاف حسابك، يرجى إنشاء تذكرة دعم لمراجعة حالة الحساب مع الإدارة.',
          },
          {
            'title': 'كيف ألغي رحلة؟',
            'answer':
                'من تفاصيل الرحلة يمكنك الإلغاء، يرجى ملاحظة أن كثرة الإلغاءات قد تؤثر على تقييمك.',
          },
          {
            'title': 'متى يحق لي إلغاء الرحلة دون تقييم سلبي؟',
            'answer':
                'يحق لك الإلغاء دون تأثير سلبي إذا تم الإلغاء قبل الموعد بـ 24 ساعة، أو في الحالات الطارئة المبررة.',
          },
          {
            'title': 'كيف أقيّم الراكب بعد انتهاء الرحلة؟',
            'answer':
                'بعد إنهاء الرحلة، ستظهر شاشة التقييم حيث يمكنك تقييم الراكب وكتابة ملاحظاتك.',
          },
          {
            'title': 'ماذا أفعل إذا لم يحضر الراكب في الموعد؟',
            'answer':
                'يرجى الانتظار للمدة المحددة بالنظام، وبعدها يمكنك إلغاء الحجز واختيار سبب عدم حضور الراكب.',
          },
          {
            'title': 'كيف أعرف تفاصيل تسعيرة الرحلة؟',
            'answer':
                'يمكنك الاطلاع على تفاصيل التسعيرة ونسبة التطبيق من خلال فاتورة الرحلة بعد انتهائها.',
          },
          {
            'title': 'هل يمكنني تغيير مسار الرحلة بعد الموافقة عليها؟',
            'answer':
                'لا يمكن تغيير المسار جذرياً بعد موافقة الركاب، ولكن يمكن التعديل البسيط بالتنسيق مع الركاب عبر المحادثة.',
          },
          {
            'title': 'ماذا أفعل في حال تعطل المركبة أثناء الرحلة؟',
            'answer':
                'يرجى التواصل الفوري مع فريق الدعم وإشعار الركاب بالمشكلة لإيجاد حل بديل.',
          },
          {
            'title': 'كيف أحصل على تقييمات إيجابية من الركاب؟',
            'answer':
                'الالتزام بالمواعيد، الحفاظ على نظافة المركبة، والقيادة الآمنة هي أهم أسباب التقييم الإيجابي.',
          },
        ];

        for (int i = 0; i < faqs.length; i++) {
          final docRef = _firestore.collection('driver_support_faq').doc();
          final newFaq = DriverFaq(
            id: docRef.id,
            title: faqs[i]['title']!,
            answer: faqs[i]['answer']!,
            order: i,
            isActive: true,
            createdAt: DateTime.now(),
          );
          batch.set(docRef, newFaq.toJson());
        }
        await batch.commit();
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  @override
  Future<String> uploadAttachment(PlatformFile file, String basePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final storageService = SupabaseStorageService();
      // Using public bucket: support/driver_support/{userId}/...
      // The basePath parameter might contain context like 'tickets', but for RLS we need conversationId or ticketId.
      final identifier = basePath.replaceAll('/', '_');

      // Convert PlatformFile to XFile since SupabaseStorageService expects XFile
      final xfile = XFile(file.path ?? '', name: file.name, bytes: file.bytes);

      return await storageService.uploadSupportAttachment(
        'driver_support',
        user.uid,
        identifier,
        xfile,
      );
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
