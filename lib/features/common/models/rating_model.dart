import 'package:equatable/equatable.dart';

class RatingModel extends Equatable {
  final String id;
  final String bookingId;
  final String tripId;
  final String reviewerId;
  final String targetId;
  final double score;
  final String comment;

  const RatingModel({
    required this.id,
    required this.bookingId,
    required this.tripId,
    required this.reviewerId,
    required this.targetId,
    required this.score,
    required this.comment,
  });

  factory RatingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RatingModel(
      id: id,
      bookingId: data['bookingId']?.toString() ?? '',
      tripId: data['tripId']?.toString() ?? '',
      reviewerId: data['reviewerId']?.toString() ?? '',
      targetId: data['targetId']?.toString() ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'tripId': tripId,
      'reviewerId': reviewerId,
      'targetId': targetId,
      'score': score,
      'comment': comment,
    };
  }

  RatingModel copyWith({
    String? id,
    String? bookingId,
    String? tripId,
    String? reviewerId,
    String? targetId,
    double? score,
    String? comment,
  }) {
    return RatingModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      tripId: tripId ?? this.tripId,
      reviewerId: reviewerId ?? this.reviewerId,
      targetId: targetId ?? this.targetId,
      score: score ?? this.score,
      comment: comment ?? this.comment,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    tripId,
    reviewerId,
    targetId,
    score,
    comment,
  ];
}
