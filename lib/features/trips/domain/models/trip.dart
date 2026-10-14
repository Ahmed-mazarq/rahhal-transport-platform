import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';
import 'stop.dart';
import 'seat.dart';

class Trip extends Equatable {
  final String id;
  final String passengerId;
  final String driverId;
  final String startLocationName;
  final String endLocationName;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final double price;
  final String currency;
  final String status;
  final String tripType;
  final String? companyId;
  final double? parcelPrice;
  final double parcelCapacityKg;
  final int parcelCountLimit;
  final DateTime createdAt;

  // Legacy fields (kept for backward compatibility if needed)
  final String departureCity;
  final String arrivalCity;

  // New Structured Geo Fields
  final String departureCountryId;
  final String departureCountry;
  final String departureProvinceId;
  final String departureProvince;
  final String departureCityId;

  final String arrivalCountryId;
  final String arrivalCountry;
  final String arrivalProvinceId;
  final String arrivalProvince;
  final String arrivalCityId;

  final DateTime departureTime;
  final DateTime arrivalTime;
  final int totalSeats;
  final int remainingSeats;
  final String vehicleType;
  final String vehiclePlate;
  final String vehicleId;
  final String vehicleBrand;
  final String vehicleModel;
  final int vehicleYear;
  final String vehicleColor;
  final String vehicleFuelType;
  final String vehiclePhotoUrl;
  final List<String> vehiclePhotoUrls;
  final String name;
  final bool isCompany;
  final String driverName;
  final double driverRating;
  final String driverAvatar;

  // Complex relationships
  final List<Stop> stops;
  final List<Seat> seatLayout;

  // Filter amenities and rules
  final bool isWomenOnly;
  final bool isFamilyOnly;
  final bool hasAc;
  final bool hasWifi;
  final bool hasLuggageSpace;
  final bool allowSmoking;
  final bool allowPets;
  final bool isVip;
  final bool requiresApproval;
  final String notes;

  // Driver selected payment methods for this trip
  final List<String> paymentMethodIds;

  const Trip({
    required this.id,
    this.passengerId = '',
    required this.driverId,
    required this.startLocationName,
    required this.endLocationName,
    this.startLatitude = 0.0,
    this.startLongitude = 0.0,
    this.endLatitude = 0.0,
    this.endLongitude = 0.0,
    required this.price,
    this.currency = 'YER',
    required this.status,
    this.tripType = 'inside_yemen',
    this.companyId,
    this.parcelPrice,
    this.parcelCapacityKg = 50.0,
    this.parcelCountLimit = 10,
    required this.createdAt,
    this.departureCity = '',
    this.arrivalCity = '',
    this.departureCountryId = '',
    this.departureCountry = '',
    this.departureProvinceId = '',
    this.departureProvince = '',
    this.departureCityId = '',
    this.arrivalCountryId = '',
    this.arrivalCountry = '',
    this.arrivalProvinceId = '',
    this.arrivalProvince = '',
    this.arrivalCityId = '',
    required this.departureTime,
    required this.arrivalTime,
    this.totalSeats = 4,
    this.remainingSeats = 4,
    this.vehicleType = 'صالون اقتصادية',
    this.vehiclePlate = '',
    this.vehicleId = '',
    this.vehicleBrand = '',
    this.vehicleModel = '',
    this.vehicleYear = 2020,
    this.vehicleColor = '',
    this.vehicleFuelType = 'بنزين',
    this.vehiclePhotoUrl = '',
    this.vehiclePhotoUrls = const [],
    this.name = '',
    this.isCompany = false,
    this.driverName = 'كابتن رحال',
    this.driverRating = 5.0,
    this.driverAvatar = '',
    this.stops = const [],
    this.seatLayout = const [],
    this.isWomenOnly = false,
    this.isFamilyOnly = false,
    this.hasAc = true,
    this.hasWifi = false,
    this.hasLuggageSpace = true,
    this.allowSmoking = false,
    this.allowPets = false,
    this.isVip = false,
    this.requiresApproval = false,
    this.notes = '',
    this.paymentMethodIds = const [],
  });

  Trip copyWith({
    String? id,
    String? passengerId,
    String? driverId,
    String? startLocationName,
    String? endLocationName,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    double? price,
    String? currency,
    String? status,
    String? tripType,
    String? companyId,
    double? parcelPrice,
    double? parcelCapacityKg,
    int? parcelCountLimit,
    DateTime? createdAt,
    String? departureCity,
    String? arrivalCity,
    String? departureCountryId,
    String? departureCountry,
    String? departureProvinceId,
    String? departureProvince,
    String? departureCityId,
    String? arrivalCountryId,
    String? arrivalCountry,
    String? arrivalProvinceId,
    String? arrivalProvince,
    String? arrivalCityId,
    DateTime? departureTime,
    DateTime? arrivalTime,
    int? totalSeats,
    int? remainingSeats,
    String? vehicleType,
    String? vehiclePlate,
    String? vehicleId,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColor,
    String? vehicleFuelType,
    String? vehiclePhotoUrl,
    List<String>? vehiclePhotoUrls,
    String? name,
    bool? isCompany,
    String? driverName,
    double? driverRating,
    String? driverAvatar,
    List<Stop>? stops,
    List<Seat>? seatLayout,
    bool? isWomenOnly,
    bool? isFamilyOnly,
    bool? hasAc,
    bool? hasWifi,
    bool? hasLuggageSpace,
    bool? allowSmoking,
    bool? allowPets,
    bool? isVip,
    bool? requiresApproval,
    String? notes,
    List<String>? paymentMethodIds,
  }) {
    return Trip(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      startLocationName: startLocationName ?? this.startLocationName,
      endLocationName: endLocationName ?? this.endLocationName,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      tripType: tripType ?? this.tripType,
      companyId: companyId ?? this.companyId,
      parcelPrice: parcelPrice ?? this.parcelPrice,
      parcelCapacityKg: parcelCapacityKg ?? this.parcelCapacityKg,
      parcelCountLimit: parcelCountLimit ?? this.parcelCountLimit,
      createdAt: createdAt ?? this.createdAt,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      departureCountryId: departureCountryId ?? this.departureCountryId,
      departureCountry: departureCountry ?? this.departureCountry,
      departureProvinceId: departureProvinceId ?? this.departureProvinceId,
      departureProvince: departureProvince ?? this.departureProvince,
      departureCityId: departureCityId ?? this.departureCityId,
      arrivalCountryId: arrivalCountryId ?? this.arrivalCountryId,
      arrivalCountry: arrivalCountry ?? this.arrivalCountry,
      arrivalProvinceId: arrivalProvinceId ?? this.arrivalProvinceId,
      arrivalProvince: arrivalProvince ?? this.arrivalProvince,
      arrivalCityId: arrivalCityId ?? this.arrivalCityId,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      totalSeats: totalSeats ?? this.totalSeats,
      remainingSeats: remainingSeats ?? this.remainingSeats,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleFuelType: vehicleFuelType ?? this.vehicleFuelType,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      vehiclePhotoUrls: vehiclePhotoUrls ?? this.vehiclePhotoUrls,
      name: name ?? this.name,
      isCompany: isCompany ?? this.isCompany,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      stops: stops ?? this.stops,
      seatLayout: seatLayout ?? this.seatLayout,
      isWomenOnly: isWomenOnly ?? this.isWomenOnly,
      isFamilyOnly: isFamilyOnly ?? this.isFamilyOnly,
      hasAc: hasAc ?? this.hasAc,
      hasWifi: hasWifi ?? this.hasWifi,
      hasLuggageSpace: hasLuggageSpace ?? this.hasLuggageSpace,
      allowSmoking: allowSmoking ?? this.allowSmoking,
      allowPets: allowPets ?? this.allowPets,
      isVip: isVip ?? this.isVip,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      notes: notes ?? this.notes,
      paymentMethodIds: paymentMethodIds ?? this.paymentMethodIds,
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

  static List<Stop> _parseStops(dynamic value) {
    if (value is! List) return const [];
    try {
      return value
          .map(
            (e) => e is String
                ? Stop(id: e, name: e, orderIndex: 0)
                : Stop.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<Seat> _parseSeatLayout(dynamic value) {
    if (value is! List) return const [];
    try {
      return value
          .map((e) => Seat.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    try {
      return value.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString() ?? '',
      passengerId: json['passengerId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      startLocationName: json['startLocationName']?.toString() ?? '',
      endLocationName: json['endLocationName']?.toString() ?? '',
      startLatitude: _parseDouble(json['startLatitude'], 0.0),
      startLongitude: _parseDouble(json['startLongitude'], 0.0),
      endLatitude: _parseDouble(json['endLatitude'], 0.0),
      endLongitude: _parseDouble(json['endLongitude'], 0.0),
      price: _parseDouble(json['price'], 0.0),
      currency: json['currency']?.toString() ?? 'YER',
      status: json['status']?.toString() ?? 'published',
      tripType: json['tripType']?.toString() ?? 'inside_yemen',
      companyId: json['companyId']?.toString(),
      parcelPrice: (json['parcelPrice'] as num?)?.toDouble(),
      parcelCapacityKg: (json['parcelCapacityKg'] as num?)?.toDouble() ?? 50.0,
      parcelCountLimit: (json['parcelCountLimit'] as num?)?.toInt() ?? 10,
      createdAt: DateParser.parse(json['createdAt']),
      departureCity: json['departureCity']?.toString() ?? '',
      arrivalCity: json['arrivalCity']?.toString() ?? '',
      departureCountryId: json['departureCountryId']?.toString() ?? '',
      departureCountry:
          json['departureCountry']?.toString() ??
          json['departureCountryName']?.toString() ??
          '',
      departureProvinceId: json['departureProvinceId']?.toString() ?? '',
      departureProvince:
          json['departureProvince']?.toString() ??
          json['departureProvinceName']?.toString() ??
          '',
      departureCityId: json['departureCityId']?.toString() ?? '',
      arrivalCountryId: json['arrivalCountryId']?.toString() ?? '',
      arrivalCountry:
          json['arrivalCountry']?.toString() ??
          json['arrivalCountryName']?.toString() ??
          '',
      arrivalProvinceId: json['arrivalProvinceId']?.toString() ?? '',
      arrivalProvince:
          json['arrivalProvince']?.toString() ??
          json['arrivalProvinceName']?.toString() ??
          '',
      arrivalCityId: json['arrivalCityId']?.toString() ?? '',
      departureTime: DateParser.parse(json['departureTime']),
      arrivalTime: DateParser.parse(json['arrivalTime']),
      totalSeats: _parseInt(json['totalSeats'], 4),
      remainingSeats: _parseInt(json['remainingSeats'], 4),
      vehicleType: json['vehicleType']?.toString() ?? 'صالون اقتصادية',
      vehiclePlate: json['vehiclePlate']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleBrand: json['vehicleBrand']?.toString() ?? '',
      vehicleModel: json['vehicleModel']?.toString() ?? '',
      vehicleYear: _parseInt(json['vehicleYear'], 2020),
      vehicleColor: json['vehicleColor']?.toString() ?? '',
      vehicleFuelType: json['vehicleFuelType']?.toString() ?? 'بنزين',
      vehiclePhotoUrl: json['vehiclePhotoUrl']?.toString() ?? '',
      vehiclePhotoUrls: _parseStringList(json['vehiclePhotoUrls']),
      name: json['name']?.toString() ?? '',
      isCompany: _parseBool(json['isCompany'], false),
      driverName: json['driverName']?.toString() ?? 'كابتن رحال',
      driverRating: _parseDouble(json['driverRating'], 5.0),
      driverAvatar: json['driverAvatar']?.toString() ?? '',
      stops: _parseStops(json['stops']),
      seatLayout: _parseSeatLayout(json['seatLayout']),
      isWomenOnly: _parseBool(json['isWomenOnly'], false),
      isFamilyOnly: _parseBool(json['isFamilyOnly'], false),
      hasAc: _parseBool(json['hasAc'], true),
      hasWifi: _parseBool(json['hasWifi'], false),
      hasLuggageSpace: _parseBool(json['hasLuggageSpace'], true),
      allowSmoking: _parseBool(json['allowSmoking'], false),
      allowPets: _parseBool(json['allowPets'], false),
      isVip: json['isVip'] as bool? ?? false,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      paymentMethodIds: json['paymentMethodIds'] != null
          ? List<String>.from(json['paymentMethodIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'driverId': driverId,
      'startLocationName': startLocationName,
      'endLocationName': endLocationName,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'price': price,
      'currency': currency,
      'status': status,
      'tripType': tripType,
      if (companyId != null) 'companyId': companyId,
      if (parcelPrice != null) 'parcelPrice': parcelPrice,
      'parcelCapacityKg': parcelCapacityKg,
      'parcelCountLimit': parcelCountLimit,
      'createdAt': Timestamp.fromDate(createdAt),
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureCountryId': departureCountryId,
      'departureCountry': departureCountry,
      'departureProvinceId': departureProvinceId,
      'departureProvince': departureProvince,
      'departureCityId': departureCityId,
      'arrivalCountryId': arrivalCountryId,
      'arrivalCountry': arrivalCountry,
      'arrivalProvinceId': arrivalProvinceId,
      'arrivalProvince': arrivalProvince,
      'arrivalCityId': arrivalCityId,
      'departureTime': Timestamp.fromDate(departureTime),
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'totalSeats': totalSeats,
      'remainingSeats': remainingSeats,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'vehicleId': vehicleId,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'vehicleFuelType': vehicleFuelType,
      'vehiclePhotoUrl': vehiclePhotoUrl,
      'vehiclePhotoUrls': vehiclePhotoUrls,
      'name': name,
      'isCompany': isCompany,
      'driverName': driverName,
      'driverRating': driverRating,
      'driverAvatar': driverAvatar,
      'stops': stops.map((e) => e.toJson()).toList(),
      'seatLayout': seatLayout.map((e) => e.toJson()).toList(),
      'isWomenOnly': isWomenOnly,
      'isFamilyOnly': isFamilyOnly,
      'hasAc': hasAc,
      'hasWifi': hasWifi,
      'hasLuggageSpace': hasLuggageSpace,
      'allowSmoking': allowSmoking,
      'allowPets': allowPets,
      'isVip': isVip,
      'requiresApproval': requiresApproval,
      'notes': notes,
      'paymentMethodIds': paymentMethodIds,
    };
  }

  bool validate() {
    return id.isNotEmpty &&
        startLocationName.isNotEmpty &&
        endLocationName.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    id,
    passengerId,
    driverId,
    startLocationName,
    endLocationName,
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
    price,
    currency,
    status,
    tripType,
    companyId,
    parcelPrice,
    parcelCapacityKg,
    parcelCountLimit,
    createdAt,
    departureCity,
    arrivalCity,
    departureCountryId,
    departureCountry,
    departureProvinceId,
    departureProvince,
    departureCityId,
    arrivalCountryId,
    arrivalCountry,
    arrivalProvinceId,
    arrivalProvince,
    arrivalCityId,
    departureTime,
    arrivalTime,
    totalSeats,
    remainingSeats,
    vehicleType,
    vehiclePlate,
    vehicleId,
    vehicleBrand,
    vehicleModel,
    vehicleYear,
    vehicleColor,
    vehicleFuelType,
    vehiclePhotoUrl,
    vehiclePhotoUrls,
    name,
    isCompany,
    driverName,
    driverRating,
    driverAvatar,
    stops,
    seatLayout,
    isWomenOnly,
    isFamilyOnly,
    hasAc,
    hasWifi,
    hasLuggageSpace,
    allowSmoking,
    allowPets,
    isVip,
    requiresApproval,
    notes,
    paymentMethodIds,
  ];
}
