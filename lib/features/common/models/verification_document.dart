import 'package:equatable/equatable.dart';
import 'package:rahal/features/common/utils/date_parser.dart';

class VerificationDocument extends Equatable {
  final String url;
  final String
  status; // uploaded, approved, rejected, needs_reupload, pending_review
  final String notes; // Admin notes if rejected or needs_reupload
  final DateTime updatedAt;

  const VerificationDocument({
    required this.url,
    this.status = 'uploaded',
    this.notes = '',
    required this.updatedAt,
  });

  factory VerificationDocument.empty() {
    return VerificationDocument(
      url: '',
      status: 'pending_review',
      updatedAt: DateTime.now(),
    );
  }

  VerificationDocument copyWith({
    String? url,
    String? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return VerificationDocument(
      url: url ?? this.url,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'status': status,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      url: json['url'] ?? '',
      status: json['status'] ?? 'pending_review',
      notes: json['notes'] ?? '',
      updatedAt: DateParser.parse(json['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [url, status, notes, updatedAt];
}
