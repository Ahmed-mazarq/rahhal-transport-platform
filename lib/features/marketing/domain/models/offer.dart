import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Offer extends Equatable {
  final String id;
  final String code; // promo code e.g. RAHHAL10
  final double discountPercent;
  final double maxDiscount;
  final DateTime expiryDate;
  final bool isActive;

  const Offer({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxDiscount,
    required this.expiryDate,
    this.isActive = true,
  });

  Offer copyWith({
    String? id,
    String? code,
    double? discountPercent,
    double? maxDiscount,
    DateTime? expiryDate,
    bool? isActive,
  }) {
    return Offer(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 0.0,
      expiryDate: DateParser.parse(json['expiryDate']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discountPercent': discountPercent,
      'maxDiscount': maxDiscount,
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  bool validate() {
    return id.isNotEmpty && code.isNotEmpty && discountPercent > 0.0;
  }

  @override
  List<Object?> get props => [
    id,
    code,
    discountPercent,
    maxDiscount,
    expiryDate,
    isActive,
  ];
}
