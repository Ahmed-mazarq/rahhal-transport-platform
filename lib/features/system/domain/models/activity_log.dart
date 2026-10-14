import 'package:equatable/equatable.dart';
import 'package:rahal/features/common/utils/date_parser.dart';

class ActivityLog extends Equatable {
  final String id;
  final String userId;
  final String action; // e.g. login, booking_created, profile_updated
  final String details;
  final DateTime timestamp;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.action,
    this.details = '',
    required this.timestamp,
  });

  ActivityLog copyWith({
    String? id,
    String? userId,
    String? action,
    String? details,
    DateTime? timestamp,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      details: json['details'] as String? ?? '',
      timestamp: DateParser.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty && userId.isNotEmpty && action.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, userId, action, details, timestamp];
}
