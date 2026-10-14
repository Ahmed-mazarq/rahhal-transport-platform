import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class DriverTicket extends Equatable {
  final String ticketId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String driverId;
  final String? conversationId;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverTicket({
    required this.ticketId,
    required this.title,
    required this.description,
    this.status = 'open',
    this.priority = 'low',
    required this.driverId,
    this.conversationId,
    this.category = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverTicket.fromJson(Map<String, dynamic> json, String id) {
    return DriverTicket(
      ticketId: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'low',
      driverId: json['driverId'] ?? json['userId'] ?? '',
      conversationId: json['conversationId'],
      category: json['category'] ?? '',
      createdAt: DateParser.parse(json['createdAt']),
      updatedAt: DateParser.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'driverId': driverId,
      if (conversationId != null) 'conversationId': conversationId,
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
    driverId,
    conversationId,
    category,
    createdAt,
    updatedAt,
  ];
}
