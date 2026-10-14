import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String
  type; // Bank Account, IBAN, Al-Kuraimi, OneCash, STC Pay, UrPay, Cash, Other
  final String providerName; // e.g., Al-Kuraimi
  final String accountNumber;
  final String accountHolderName;
  final bool isDefault;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.providerName,
    required this.accountNumber,
    required this.accountHolderName,
    this.isDefault = false,
    this.isActive = true,
  });

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? providerName,
    String? accountNumber,
    String? accountHolderName,
    bool? isDefault,
    bool? isActive,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      providerName: providerName ?? this.providerName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      accountHolderName: json['accountHolderName'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'providerName': providerName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    providerName,
    accountNumber,
    accountHolderName,
    isDefault,
    isActive,
  ];
}
