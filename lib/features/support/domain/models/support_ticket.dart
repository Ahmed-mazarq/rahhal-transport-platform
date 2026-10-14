import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class SupportTicket extends Equatable {
  final String ticketId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String userId;
  final String? conversationId;
  final String category;
  final String userType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.ticketId,
    required this.title,
    required this.description,
    this.status = 'open',
    this.priority = 'low',
    required this.userId,
    this.conversationId,
    this.category = '',
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json, String id) {
    return SupportTicket(
      ticketId: id,
      title: json['title'] ?? 'بدون عنوان',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'low',
      userId: json['userId'] ?? json['driverId'] ?? '',
      conversationId: json['conversationId'],
      category: json['category'] ?? '',
      userType: json['userType'] ?? json['prefix'] ?? 'passenger',
      createdAt: DateParser.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateParser.parse(json['updatedAt'])
          : DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'userId': userId,
      if (conversationId != null) 'conversationId': conversationId,
      'category': category,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    ticketId,
    title,
    description,
    status,
    priority,
    userId,
    conversationId,
    category,
    userType,
    createdAt,
    updatedAt,
  ];
}
