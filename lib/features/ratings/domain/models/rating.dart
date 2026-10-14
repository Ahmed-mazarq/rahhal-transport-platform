import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Rating extends Equatable {
  final String id;
  final String tripId;
  final String reviewerId;
  final String revieweeId;
  final double score;
  final String comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.tripId,
    required this.reviewerId,
    required this.revieweeId,
    required this.score,
    this.comment = '',
    required this.createdAt,
  });

  Rating copyWith({
    String? id,
    String? tripId,
    String? reviewerId,
    String? revieweeId,
    double? score,
    String? comment,
    DateTime? createdAt,
  }) {
    return Rating(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      reviewerId: json['reviewerId'] as String? ?? '',
      revieweeId: json['revieweeId'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'score': score,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty && tripId.isNotEmpty && score >= 1.0 && score <= 5.0;
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    reviewerId,
    revieweeId,
    score,
    comment,
    createdAt,
  ];
}
