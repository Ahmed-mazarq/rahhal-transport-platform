import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String userId;
  final String type; // credit_card, apple_pay, mada, cash
  final String lastFourDigits;
  final String providerName; // e.g. Visa, Mastercard

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.lastFourDigits = '',
    this.providerName = '',
  });

  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? type,
    String? lastFourDigits,
    String? providerName,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      providerName: providerName ?? this.providerName,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'cash',
      lastFourDigits: json['lastFourDigits'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'lastFourDigits': lastFourDigits,
      'providerName': providerName,
    };
  }

  bool validate() {
    return id.isNotEmpty && userId.isNotEmpty && type.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, userId, type, lastFourDigits, providerName];
}
