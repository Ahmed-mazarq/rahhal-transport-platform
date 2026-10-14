import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class VerificationRequest extends Equatable {
  final String id;
  final String driverId;
  final String status; // pending, approved, rejected
  final String rejectionReason;
  final DateTime createdAt;

  const VerificationRequest({
    required this.id,
    required this.driverId,
    required this.status,
    this.rejectionReason = '',
    required this.createdAt,
  });

  VerificationRequest copyWith({
    String? id,
    String? driverId,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String? ?? '',
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty && driverId.isNotEmpty && status.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, driverId, status, rejectionReason, createdAt];
}
