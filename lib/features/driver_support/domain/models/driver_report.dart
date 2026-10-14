import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class DriverReport extends Equatable {
  final String reportId;
  final String category;
  final String subCategory;
  final String description;
  final List<String> images;
  final String reporterId; // DriverId
  final String? reportedId;
  final String? reportedType;
  final String? tripId;
  final String? bookingId;
  final String? companyId;
  final String status;
  final String priority;
  final String? conversationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverReport({
    required this.reportId,
    required this.category,
    required this.subCategory,
    required this.description,
    this.images = const [],
    required this.reporterId,
    this.reportedId,
    this.reportedType,
    this.tripId,
    this.bookingId,
    this.companyId,
    this.status = 'open',
    this.priority = 'low',
    this.conversationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverReport.fromJson(Map<String, dynamic> json, String id) {
    return DriverReport(
      reportId: id,
      category:
          json['category'] ??
          json['reason'] ??
          '', // Fallback to reason for old data
      subCategory: json['subCategory'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      reporterId: json['reporterId'] ?? json['driverId'] ?? '',
      reportedId: json['reportedId'],
      reportedType: json['reportedType'],
      tripId: json['tripId'],
      bookingId: json['bookingId'],
      companyId: json['companyId'],
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'low',
      conversationId: json['conversationId'],
      createdAt: DateParser.parse(json['createdAt']),
      updatedAt: DateParser.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'images': images,
      'reporterType': 'driver',
      'reporterId': reporterId,
      'driverId': reporterId, // Redundant but good for queries
      if (reportedId != null) 'reportedId': reportedId,
      if (reportedType != null) 'reportedType': reportedType,
      if (tripId != null) 'tripId': tripId,
      if (bookingId != null) 'bookingId': bookingId,
      if (companyId != null) 'companyId': companyId,
      'status': status,
      'priority': priority,
      if (conversationId != null) 'conversationId': conversationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    reportId,
    category,
    subCategory,
    description,
    images,
    reporterId,
    reportedId,
    reportedType,
    tripId,
    bookingId,
    companyId,
    status,
    priority,
    conversationId,
    createdAt,
    updatedAt,
  ];
}
