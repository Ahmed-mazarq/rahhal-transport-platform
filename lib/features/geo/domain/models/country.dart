import 'package:equatable/equatable.dart';

class Country extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String code; // e.g. SA, EG
  final String phoneCode; // e.g. +966, +20

  const Country({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.code,
    required this.phoneCode,
  });

  Country copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? code,
    String? phoneCode,
  }) {
    return Country(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      code: code ?? this.code,
      phoneCode: phoneCode ?? this.phoneCode,
    );
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      code: json['code'] as String? ?? '',
      phoneCode: json['phoneCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'code': code,
      'phoneCode': phoneCode,
    };
  }

  bool validate() {
    return id.isNotEmpty &&
        nameAr.isNotEmpty &&
        code.isNotEmpty &&
        phoneCode.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, code, phoneCode];
}
