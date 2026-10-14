import 'package:equatable/equatable.dart';

class ReportModel extends Equatable {
  final String id;
  final String reporterId;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReportModel(
      id: id,
      reporterId: data['reporterId']?.toString() ?? '',
      targetId: data['targetId']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? targetId,
    String? reason,
    String? status,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reporterId,
    targetId,
    reason,
    status,
    createdAt,
  ];
}
