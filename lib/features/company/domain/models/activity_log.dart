import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  final String id;
  final String companyId;
  final String action; // e.g. "Trip Created", "Role Changed"
  final String description;
  final String performedBy; // Employee Name or ID
  final DateTime timestamp;

  const ActivityLog({
    required this.id,
    required this.companyId,
    required this.action,
    required this.description,
    required this.performedBy,
    required this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
      performedBy: json['performedBy'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'action': action,
      'description': description,
      'performedBy': performedBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    action,
    description,
    performedBy,
    timestamp,
  ];
}
