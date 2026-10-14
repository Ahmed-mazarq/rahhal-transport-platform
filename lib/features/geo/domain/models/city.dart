import 'package:equatable/equatable.dart';

class City extends Equatable {
  final String id;
  final String governorateId;
  final String nameAr;
  final String nameEn;

  const City({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
  });

  City copyWith({
    String? id,
    String? governorateId,
    String? nameAr,
    String? nameEn,
  }) {
    return City(
      id: id ?? this.id,
      governorateId: governorateId ?? this.governorateId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
    );
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String? ?? '',
      governorateId: json['governorateId'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'governorateId': governorateId,
      'nameAr': nameAr,
      'nameEn': nameEn,
    };
  }

  bool validate() {
    return id.isNotEmpty && governorateId.isNotEmpty && nameAr.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, governorateId, nameAr, nameEn];
}
