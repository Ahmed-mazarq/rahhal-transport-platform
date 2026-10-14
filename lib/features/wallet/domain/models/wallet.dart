import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final String userId; // Can be passenger or driver ID
  final double balance;
  final String currency;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'SAR',
  });

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    String? currency,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'SAR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'currency': currency,
    };
  }

  bool validate() {
    return id.isNotEmpty && userId.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, userId, balance, currency];
}
