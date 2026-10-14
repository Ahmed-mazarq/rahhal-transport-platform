import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class DriverPaymentMethod extends Equatable {
  final String id;
  final String driverId;
  final String type; // e.g., bank, wallet
  final String providerName; // e.g., Al-Rajhi, Al-Kuraimi
  final String country;
  final String currency;
  final String accountNumber;
  final String accountHolderName;
  final String iban;
  final bool isActive;
  final String approvalStatus; // pending, approved, rejected
  final String approvedBy;
  final DateTime? approvedAt;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverPaymentMethod({
    required this.id,
    required this.driverId,
    required this.type,
    required this.providerName,
    this.country = '',
    this.currency = '',
    this.accountNumber = '',
    this.accountHolderName = '',
    this.iban = '',
    this.isActive = true,
    this.approvalStatus = 'not_required',
    this.approvedBy = '',
    this.approvedAt,
    this.rejectionReason = '',
    this.createdAt,
    this.updatedAt,
  });

  factory DriverPaymentMethod.fromJson(Map<String, dynamic> json) {
    return DriverPaymentMethod(
      id: json['id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      country: json['country'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      accountHolderName: json['accountHolderName'] as String? ?? '',
      iban: json['iban'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      approvalStatus: json['approvalStatus'] as String? ?? 'not_required',
      approvedBy: json['approvedBy'] as String? ?? '',
      approvedAt: json['approvedAt'] != null
          ? DateParser.parse(json['approvedAt'])
          : null,
      rejectionReason: json['rejectionReason'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateParser.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateParser.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'type': type,
      'providerName': providerName,
      'country': country,
      'currency': currency,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'iban': iban,
      'isActive': isActive,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      'rejectionReason': rejectionReason,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    type,
    providerName,
    country,
    currency,
    accountNumber,
    accountHolderName,
    iban,
    isActive,
    approvalStatus,
    approvedBy,
    approvedAt,
    rejectionReason,
    createdAt,
    updatedAt,
  ];
}
