import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class DriverConversation extends Equatable {
  final String conversationId;
  final String? ticketId;
  final List<String> participantIds;
  final String status;
  final String priority;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? conversationType; // 'general', 'ticket', 'report'
  final String? reportId;

  const DriverConversation({
    required this.conversationId,
    this.ticketId,
    required this.participantIds,
    this.status = 'open',
    this.priority = 'low',
    this.lastMessage,
    this.lastMessageTime,
    required this.updatedAt,
    required this.createdAt,
    this.conversationType = 'general',
    this.reportId,
  });

  factory DriverConversation.fromJson(Map<String, dynamic> json, String id) {
    return DriverConversation(
      conversationId: id,
      ticketId: json['ticketId'],
      participantIds: List<String>.from(json['participantIds'] ?? []),
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'low',
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateParser.parse(json['lastMessageTime'])
          : null,
      updatedAt: DateParser.parse(json['updatedAt']),
      createdAt: DateParser.parse(json['createdAt']),
      conversationType: json['conversationType'] ?? 'general',
      reportId: json['reportId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      if (ticketId != null) 'ticketId': ticketId,
      if (reportId != null) 'reportId': reportId,
      if (conversationType != null) 'conversationType': conversationType,
      'status': status,
      'userType': 'driver', // Constant for admin
      'priority': priority,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null)
        'lastMessageTime': lastMessageTime!.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    conversationId,
    ticketId,
    participantIds,
    status,
    priority,
    lastMessage,
    lastMessageTime,
    updatedAt,
    createdAt,
    conversationType,
    reportId,
  ];
}
