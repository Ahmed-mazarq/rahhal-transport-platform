import 'package:equatable/equatable.dart';

class WorkingArea extends Equatable {
  final String id;
  final String country; // Yemen, Saudi Arabia
  final String city; // Sana'a, Taiz, Riyadh, etc.
  final bool isActive;
  final String countryId;
  final String governorateId;
  final String governorate;
  final String cityId;

  const WorkingArea({
    required this.id,
    required this.country,
    required this.city,
    this.isActive = true,
    this.countryId = '',
    this.governorateId = '',
    this.governorate = '',
    this.cityId = '',
  });

  WorkingArea copyWith({
    String? id,
    String? country,
    String? city,
    bool? isActive,
    String? countryId,
    String? governorateId,
    String? governorate,
    String? cityId,
  }) {
    return WorkingArea(
      id: id ?? this.id,
      country: country ?? this.country,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      countryId: countryId ?? this.countryId,
      governorateId: governorateId ?? this.governorateId,
      governorate: governorate ?? this.governorate,
      cityId: cityId ?? this.cityId,
    );
  }

  factory WorkingArea.fromJson(Map<String, dynamic> json) {
    return WorkingArea(
      id: json['id'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      countryId: json['countryId'] as String? ?? '',
      governorateId: json['governorateId'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      cityId: json['cityId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'city': city,
      'isActive': isActive,
      if (countryId.isNotEmpty) 'countryId': countryId,
      if (governorateId.isNotEmpty) 'governorateId': governorateId,
      if (governorate.isNotEmpty) 'governorate': governorate,
      if (cityId.isNotEmpty) 'cityId': cityId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    country,
    city,
    isActive,
    countryId,
    governorateId,
    governorate,
    cityId,
  ];
}
