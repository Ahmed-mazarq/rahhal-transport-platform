import 'package:equatable/equatable.dart';

class BookingHistoryModel extends Equatable {
  final String id;
  final String tripId;
  final String passengerId;
  final int seats;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final DateTime completedAt;

  const BookingHistoryModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seats,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.completedAt,
  });

  factory BookingHistoryModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return BookingHistoryModel(
      id: id,
      tripId: data['tripId']?.toString() ?? '',
      passengerId: data['passengerId']?.toString() ?? '',
      seats: (data['seats'] as num?)?.toInt() ?? 0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? '',
      paymentStatus: data['paymentStatus']?.toString() ?? '',
      completedAt:
          DateTime.tryParse(data['completedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'passengerId': passengerId,
      'seats': seats,
      'totalPrice': totalPrice,
      'status': status,
      'paymentStatus': paymentStatus,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  BookingHistoryModel copyWith({
    String? id,
    String? tripId,
    String? passengerId,
    int? seats,
    double? totalPrice,
    String? status,
    String? paymentStatus,
    DateTime? completedAt,
  }) {
    return BookingHistoryModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    passengerId,
    seats,
    totalPrice,
    status,
    paymentStatus,
    completedAt,
  ];
}
