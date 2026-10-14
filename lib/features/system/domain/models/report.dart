import 'package:equatable/equatable.dart';
import 'package:rahal/features/common/utils/date_parser.dart';

class Report extends Equatable {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reason;
  final String description;
  final String status; // pending, reviewed, resolved
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedId,
    String? reason,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedId: reportedId ?? this.reportedId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      reportedId: json['reportedId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty &&
        reporterId.isNotEmpty &&
        reportedId.isNotEmpty &&
        reason.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    id,
    reporterId,
    reportedId,
    reason,
    description,
    status,
    createdAt,
  ];
}
