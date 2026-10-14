import 'package:equatable/equatable.dart';

class BookingModel extends Equatable {
  final String id;
  final String tripId;
  final String passengerId;
  final int seats;
  final double totalPrice;
  final String status;
  final String paymentStatus;

  const BookingModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seats,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
  });

  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BookingModel(
      id: id,
      tripId: data['tripId']?.toString() ?? '',
      passengerId: data['passengerId']?.toString() ?? '',
      seats: (data['seats'] as num?)?.toInt() ?? 0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? '',
      paymentStatus: data['paymentStatus']?.toString() ?? '',
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
    };
  }

  BookingModel copyWith({
    String? id,
    String? tripId,
    String? passengerId,
    int? seats,
    double? totalPrice,
    String? status,
    String? paymentStatus,
  }) {
    return BookingModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
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
  ];
}
