import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class SupportReport extends Equatable {
  final String id;
  final String status;
  final String reason;
  final String reporterType;
  final String reporterId;
  final String? reportedId;
  final String? reportedType;
  final String description;
  final String priority;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? conversationId;
  final String? tripId;
  final String? bookingId;
  final String? companyId;
  final String? driverId;

  const SupportReport({
    required this.id,
    this.status = 'open',
    required this.reason,
    required this.reporterType,
    required this.reporterId,
    this.reportedId,
    this.reportedType,
    this.description = '',
    this.priority = 'low',
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.conversationId,
    this.tripId,
    this.bookingId,
    this.companyId,
    this.driverId,
  });

  factory SupportReport.fromJson(Map<String, dynamic> json, String docId) {
    return SupportReport(
      id: docId,
      status: json['status'] ?? 'open',
      reason: json['reason'] ?? json['reportType'] ?? 'بدون سبب',
      reporterType: json['reporterType'] ?? 'غير معروف',
      reporterId: json['reporterId'] ?? '',
      reportedId: json['reportedId'] ?? json['reportedUserId'],
      reportedType: json['reportedType'],
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'low',
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateParser.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateParser.parse(json['updatedAt'])
          : DateParser.parse(json['createdAt']),
      conversationId: json['conversationId'],
      tripId: json['tripId'],
      bookingId: json['bookingId'],
      companyId: json['companyId'],
      driverId: json['driverId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'reason': reason,
      'reporterType': reporterType,
      'reporterId': reporterId,
      'reportedId': reportedId,
      if (reportedType != null) 'reportedType': reportedType,
      'description': description,
      'priority': priority,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (conversationId != null) 'conversationId': conversationId,
      if (tripId != null) 'tripId': tripId,
      if (bookingId != null) 'bookingId': bookingId,
      if (companyId != null) 'companyId': companyId,
      if (driverId != null) 'driverId': driverId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    status,
    reason,
    reporterType,
    reporterId,
    reportedId,
    reportedType,
    description,
    priority,
    attachments,
    createdAt,
    updatedAt,
  ];
}
