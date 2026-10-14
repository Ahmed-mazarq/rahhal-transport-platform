import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final String type; // e.g. credit, debit
  final String description; // Arabic text describing transaction
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    String? walletId,
    double? amount,
    String? type,
    String? description,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'credit',
      description: json['description'] as String? ?? '',
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty && walletId.isNotEmpty && amount != 0.0;
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    amount,
    type,
    description,
    createdAt,
  ];
}
