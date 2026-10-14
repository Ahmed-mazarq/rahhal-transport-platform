import 'package:equatable/equatable.dart';

class CityModel extends Equatable {
  final String id;
  final String governorateId;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;

  const CityModel({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
  });

  factory CityModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CityModel(
      id: id,
      governorateId: data['governorateId']?.toString() ?? '',
      nameAr: data['nameAr']?.toString() ?? '',
      nameEn: data['nameEn']?.toString() ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'governorateId': governorateId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'lat': lat,
      'lng': lng,
    };
  }

  CityModel copyWith({
    String? id,
    String? governorateId,
    String? nameAr,
    String? nameEn,
    double? lat,
    double? lng,
  }) {
    return CityModel(
      id: id ?? this.id,
      governorateId: governorateId ?? this.governorateId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  List<Object?> get props => [id, governorateId, nameAr, nameEn, lat, lng];
}
