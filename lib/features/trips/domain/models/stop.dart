import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Stop extends Equatable {
  final String id;
  final String name;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final bool pickupAllowed;
  final bool dropoffAllowed;
  final int orderIndex;
  final String locationNotes;
  final double latitude;
  final double longitude;
  final String countryId;
  final String provinceId;
  final String cityId;
  final String districtId;

  const Stop({
    required this.id,
    required this.name,
    this.arrivalTime,
    this.departureTime,
    this.pickupAllowed = true,
    this.dropoffAllowed = true,
    required this.orderIndex,
    this.locationNotes = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.countryId = '',
    this.provinceId = '',
    this.cityId = '',
    this.districtId = '',
  });

  Stop copyWith({
    String? id,
    String? name,
    DateTime? arrivalTime,
    DateTime? departureTime,
    bool? pickupAllowed,
    bool? dropoffAllowed,
    int? orderIndex,
    String? locationNotes,
    double? latitude,
    double? longitude,
    String? countryId,
    String? provinceId,
    String? cityId,
    String? districtId,
  }) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      pickupAllowed: pickupAllowed ?? this.pickupAllowed,
      dropoffAllowed: dropoffAllowed ?? this.dropoffAllowed,
      orderIndex: orderIndex ?? this.orderIndex,
      locationNotes: locationNotes ?? this.locationNotes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      countryId: countryId ?? this.countryId,
      provinceId: provinceId ?? this.provinceId,
      cityId: cityId ?? this.cityId,
      districtId: districtId ?? this.districtId,
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic value, bool fallback) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      arrivalTime: json['arrivalTime'] != null
          ? DateParser.parse(json['arrivalTime'])
          : null,
      departureTime: json['departureTime'] != null
          ? DateParser.parse(json['departureTime'])
          : null,
      pickupAllowed: _parseBool(json['pickupAllowed'], true),
      dropoffAllowed: _parseBool(json['dropoffAllowed'], true),
      orderIndex: _parseInt(json['orderIndex'], 0),
      locationNotes: json['locationNotes']?.toString() ?? '',
      latitude: _parseDouble(json['latitude'], 0.0),
      longitude: _parseDouble(json['longitude'], 0.0),
      countryId: json['countryId']?.toString() ?? '',
      provinceId: json['provinceId']?.toString() ?? '',
      cityId: json['cityId']?.toString() ?? '',
      districtId: json['districtId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arrivalTime': arrivalTime?.toIso8601String(),
      'departureTime': departureTime?.toIso8601String(),
      'pickupAllowed': pickupAllowed,
      'dropoffAllowed': dropoffAllowed,
      'orderIndex': orderIndex,
      'locationNotes': locationNotes,
      'latitude': latitude,
      'longitude': longitude,
      'countryId': countryId,
      'provinceId': provinceId,
      'cityId': cityId,
      'districtId': districtId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    arrivalTime,
    departureTime,
    pickupAllowed,
    dropoffAllowed,
    orderIndex,
    locationNotes,
    latitude,
    longitude,
    countryId,
    provinceId,
    cityId,
    districtId,
  ];
}
