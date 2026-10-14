import 'package:equatable/equatable.dart';

class Governorate extends Equatable {
  final String id;
  final String countryId;
  final String nameAr;
  final String nameEn;

  const Governorate({
    required this.id,
    required this.countryId,
    required this.nameAr,
    required this.nameEn,
  });

  Governorate copyWith({
    String? id,
    String? countryId,
    String? nameAr,
    String? nameEn,
  }) {
    return Governorate(
      id: id ?? this.id,
      countryId: countryId ?? this.countryId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
    );
  }

  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['id'] as String? ?? '',
      countryId: json['countryId'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'countryId': countryId,
      'nameAr': nameAr,
      'nameEn': nameEn,
    };
  }

  bool validate() {
    return id.isNotEmpty && countryId.isNotEmpty && nameAr.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, countryId, nameAr, nameEn];
}
