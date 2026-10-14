import 'package:equatable/equatable.dart';
import 'package:rahal/features/common/utils/date_parser.dart';

class Notification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String
  category; // system, trip, booking, wallet, payment, support, document, security, promotion, general
  final String targetRole; // passenger, driver, company, all
  final Map<String, dynamic> payload;
  final String priority; // low, normal, high

  // Admin tracking fields
  final String status; // draft, scheduled, sent
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String createdBy;
  final int readCount;
  final int deliveredCount;
  final int failedCount;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.category = 'general',
    this.targetRole = 'all',
    this.payload = const {},
    this.priority = 'normal',

    this.status = 'sent',
    this.scheduledAt,
    this.sentAt,
    this.createdBy = 'system',
    this.readCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
  });

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    String? category,
    String? targetRole,
    Map<String, dynamic>? payload,
    String? priority,
    String? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? createdBy,
    int? readCount,
    int? deliveredCount,
    int? failedCount,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      targetRole: targetRole ?? this.targetRole,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      createdBy: createdBy ?? this.createdBy,
      readCount: readCount ?? this.readCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    try {
      return Notification(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isRead: json['isRead'] == true,
        createdAt: DateParser.parse(json['createdAt']),
        category:
            json['category']?.toString() ??
            json['type']?.toString() ??
            'general',
        targetRole: json['targetRole']?.toString() ?? 'all',
        payload: json['payload'] is Map
            ? (json['payload'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              )
            : const {},
        priority: json['priority']?.toString() ?? 'normal',
        status: json['status']?.toString() ?? 'sent',
        scheduledAt: json['scheduledAt'] != null
            ? DateParser.parse(json['scheduledAt'])
            : null,
        sentAt: json['sentAt'] != null
            ? DateParser.parse(json['sentAt'])
            : null,
        createdBy: json['createdBy']?.toString() ?? 'system',
        readCount: json['readCount'] is int
            ? json['readCount']
            : int.tryParse(json['readCount']?.toString() ?? '0') ?? 0,
        deliveredCount: json['deliveredCount'] is int
            ? json['deliveredCount']
            : int.tryParse(json['deliveredCount']?.toString() ?? '0') ?? 0,
        failedCount: json['failedCount'] is int
            ? json['failedCount']
            : int.tryParse(json['failedCount']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      return Notification(
        id: json['id']?.toString() ?? 'fallback_id',
        userId: json['userId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'targetRole': targetRole,
      'payload': payload,
      'priority': priority,
      'status': status,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'createdBy': createdBy,
      'readCount': readCount,
      'deliveredCount': deliveredCount,
      'failedCount': failedCount,
    };
  }

  bool validate() {
    return id.isNotEmpty && title.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    body,
    isRead,
    createdAt,
    category,
    targetRole,
    payload,
    priority,
    status,
    scheduledAt,
    sentAt,
    createdBy,
    readCount,
    deliveredCount,
    failedCount,
  ];
}
