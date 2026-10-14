import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class ParcelDelivery extends Equatable {
  final String id;
  final String trackingNumber;
  final String? qrCodeValue;

  final String senderId;
  final String senderName;
  final String senderPhone;

  final Map<String, dynamic>? senderSnapshot;
  final double? pickupLatitude;
  final double? pickupLongitude;

  final String receiverName;
  final String receiverPhone;
  final String receiverCountry;
  final String? receiverProvince;
  final String receiverCity;
  final String? receiverDistrict;
  final String receiverAddress;

  final String originCountryId;
  final String originCountry;
  final String originProvinceId;
  final String originProvince;
  final String originCityId;
  final String originCity;
  final String? originAddress;

  final String destinationCountryId;
  final String destinationCountry;
  final String destinationProvinceId;
  final String destinationProvince;
  final String destinationCityId;
  final String destinationCity;
  final String? destinationAddress;

  final String? originDistrictId;
  final String? originDistrict;
  final String? destinationDistrictId;
  final String? destinationDistrict;

  final String? tripId;

  final String? carrierType; // 'driver' or 'company'
  final String? driverId;
  final String? companyId;
  final String? vehicleId;

  // Carrier snapshot
  final String? carrierName;
  final double? carrierRating;
  final int? carrierTripsCount;
  final String? vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;

  final String category;
  final String description;
  final double declaredValue;
  final double weight;
  final String size;
  final int pieceCount;
  final bool isFragile;
  final String specialInstructions;

  final String pickupMethod;
  final String deliveryMethod;

  final double price;
  final String currency;

  final String status;

  final List<String> senderPhotos;
  final List<String> pickupPhotos;
  final List<String> deliveryPhotos;

  final String? pickupVerificationCode;
  final String? deliveryVerificationCode;

  final DateTime? pickupVerifiedAt;
  final DateTime? deliveredAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String? rejectionReason;
  final String? rejectedBy;
  final DateTime? rejectedAt;

  const ParcelDelivery({
    required this.id,
    required this.trackingNumber,
    this.qrCodeValue,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    this.senderSnapshot,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverCountry,
    this.receiverProvince,
    required this.receiverCity,
    this.receiverDistrict,
    required this.receiverAddress,
    required this.originCountryId,
    required this.originCountry,
    required this.originProvinceId,
    required this.originProvince,
    required this.originCityId,
    required this.originCity,
    this.originAddress,
    required this.destinationCountryId,
    required this.destinationCountry,
    required this.destinationProvinceId,
    required this.destinationProvince,
    required this.destinationCityId,
    required this.destinationCity,
    this.destinationAddress,
    this.originDistrictId,
    this.originDistrict,
    this.destinationDistrictId,
    this.destinationDistrict,
    this.tripId,
    this.carrierType,
    this.driverId,
    this.companyId,
    this.vehicleId,
    this.carrierName,
    this.carrierRating,
    this.carrierTripsCount,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    required this.category,
    this.description = '',
    this.declaredValue = 0.0,
    required this.weight,
    required this.size,
    this.pieceCount = 1,
    this.isFragile = false,
    this.specialInstructions = '',
    required this.pickupMethod,
    required this.deliveryMethod,
    this.price = 0.0,
    this.currency = 'SAR',
    required this.status,
    this.senderPhotos = const [],
    this.pickupPhotos = const [],
    this.deliveryPhotos = const [],
    this.pickupVerificationCode,
    this.deliveryVerificationCode,
    this.pickupVerifiedAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.rejectedBy,
    this.rejectedAt,
  });

  ParcelDelivery copyWith({
    String? id,
    String? trackingNumber,
    String? qrCodeValue,
    String? senderId,
    String? senderName,
    String? senderPhone,
    Map<String, dynamic>? senderSnapshot,
    double? pickupLatitude,
    double? pickupLongitude,
    String? receiverName,
    String? receiverPhone,
    String? receiverCountry,
    String? receiverProvince,
    String? receiverCity,
    String? receiverDistrict,
    String? receiverAddress,
    String? originCountryId,
    String? originCountry,
    String? originProvinceId,
    String? originProvince,
    String? originCityId,
    String? originCity,
    String? originAddress,
    String? destinationCountryId,
    String? destinationCountry,
    String? destinationProvinceId,
    String? destinationProvince,
    String? destinationCityId,
    String? destinationCity,
    String? destinationAddress,
    String? originDistrictId,
    String? originDistrict,
    String? destinationDistrictId,
    String? destinationDistrict,
    String? tripId,
    String? carrierType,
    String? driverId,
    String? companyId,
    String? vehicleId,
    String? carrierName,
    double? carrierRating,
    int? carrierTripsCount,
    String? vehicleType,
    String? vehicleModel,
    String? vehicleColor,
    String? category,
    String? description,
    double? declaredValue,
    double? weight,
    String? size,
    int? pieceCount,
    bool? isFragile,
    String? specialInstructions,
    String? pickupMethod,
    String? deliveryMethod,
    double? price,
    String? currency,
    String? status,
    List<String>? senderPhotos,
    List<String>? pickupPhotos,
    List<String>? deliveryPhotos,
    String? pickupVerificationCode,
    String? deliveryVerificationCode,
    DateTime? pickupVerifiedAt,
    DateTime? deliveredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rejectionReason,
    String? rejectedBy,
    DateTime? rejectedAt,
  }) {
    return ParcelDelivery(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderSnapshot: senderSnapshot ?? this.senderSnapshot,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverCountry: receiverCountry ?? this.receiverCountry,
      receiverProvince: receiverProvince ?? this.receiverProvince,
      receiverCity: receiverCity ?? this.receiverCity,
      receiverDistrict: receiverDistrict ?? this.receiverDistrict,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      originCountryId: originCountryId ?? this.originCountryId,
      originCountry: originCountry ?? this.originCountry,
      originProvinceId: originProvinceId ?? this.originProvinceId,
      originProvince: originProvince ?? this.originProvince,
      originCityId: originCityId ?? this.originCityId,
      originCity: originCity ?? this.originCity,
      originAddress: originAddress ?? this.originAddress,
      destinationCountryId: destinationCountryId ?? this.destinationCountryId,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      destinationProvinceId:
          destinationProvinceId ?? this.destinationProvinceId,
      destinationProvince: destinationProvince ?? this.destinationProvince,
      destinationCityId: destinationCityId ?? this.destinationCityId,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      originDistrictId: originDistrictId ?? this.originDistrictId,
      originDistrict: originDistrict ?? this.originDistrict,
      destinationDistrictId:
          destinationDistrictId ?? this.destinationDistrictId,
      destinationDistrict: destinationDistrict ?? this.destinationDistrict,
      tripId: tripId ?? this.tripId,
      carrierType: carrierType ?? this.carrierType,
      driverId: driverId ?? this.driverId,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      carrierName: carrierName ?? this.carrierName,
      carrierRating: carrierRating ?? this.carrierRating,
      carrierTripsCount: carrierTripsCount ?? this.carrierTripsCount,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      category: category ?? this.category,
      description: description ?? this.description,
      declaredValue: declaredValue ?? this.declaredValue,
      weight: weight ?? this.weight,
      size: size ?? this.size,
      pieceCount: pieceCount ?? this.pieceCount,
      isFragile: isFragile ?? this.isFragile,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      pickupMethod: pickupMethod ?? this.pickupMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      senderPhotos: senderPhotos ?? this.senderPhotos,
      pickupPhotos: pickupPhotos ?? this.pickupPhotos,
      deliveryPhotos: deliveryPhotos ?? this.deliveryPhotos,
      pickupVerificationCode:
          pickupVerificationCode ?? this.pickupVerificationCode,
      deliveryVerificationCode:
          deliveryVerificationCode ?? this.deliveryVerificationCode,
      pickupVerifiedAt: pickupVerifiedAt ?? this.pickupVerifiedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }

  factory ParcelDelivery.fromJson(Map<String, dynamic> json) {
    return ParcelDelivery(
      id: json['id'] as String? ?? '',
      trackingNumber: json['trackingNumber'] as String? ?? '',
      qrCodeValue: json['qrCodeValue'] as String?,
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderPhone: json['senderPhone'] as String? ?? '',
      senderSnapshot: json['senderSnapshot'] as Map<String, dynamic>?,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhone: json['receiverPhone'] as String? ?? '',
      receiverCountry: json['receiverCountry'] as String? ?? '',
      receiverProvince: json['receiverProvince'] as String?,
      receiverCity: json['receiverCity'] as String? ?? '',
      receiverDistrict: json['receiverDistrict'] as String?,
      receiverAddress: json['receiverAddress'] as String? ?? '',
      originCountryId: json['originCountryId'] as String? ?? '',
      originCountry: json['originCountry'] as String? ?? '',
      originProvinceId: json['originProvinceId'] as String? ?? '',
      originProvince: json['originProvince'] as String? ?? '',
      originCityId: json['originCityId'] as String? ?? '',
      originCity: json['originCity'] as String? ?? '',
      originAddress: json['originAddress'] as String?,
      destinationCountryId: json['destinationCountryId'] as String? ?? '',
      destinationCountry: json['destinationCountry'] as String? ?? '',
      destinationProvinceId: json['destinationProvinceId'] as String? ?? '',
      destinationProvince: json['destinationProvince'] as String? ?? '',
      destinationCityId: json['destinationCityId'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      destinationAddress: json['destinationAddress'] as String?,
      originDistrictId: json['originDistrictId'] as String?,
      originDistrict: json['originDistrict'] as String?,
      destinationDistrictId: json['destinationDistrictId'] as String?,
      destinationDistrict: json['destinationDistrict'] as String?,
      tripId: json['tripId'] as String?,
      carrierType: json['carrierType'] as String?,
      driverId: json['driverId'] as String?,
      companyId: json['companyId'] as String?,
      vehicleId: json['vehicleId'] as String?,
      carrierName: json['carrierName'] as String?,
      carrierRating: (json['carrierRating'] as num?)?.toDouble(),
      carrierTripsCount: json['carrierTripsCount'] as int?,
      vehicleType: json['vehicleType'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      vehicleColor: json['vehicleColor'] as String?,
      category: json['category'] as String? ?? 'مستندات',
      description: json['description'] as String? ?? '',
      declaredValue: (json['declaredValue'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      size: json['size'] as String? ?? 'small',
      pieceCount: json['pieceCount'] as int? ?? 1,
      isFragile: json['isFragile'] as bool? ?? false,
      specialInstructions: json['specialInstructions'] as String? ?? '',
      pickupMethod: json['pickupMethod'] as String? ?? 'drop_off',
      deliveryMethod: json['deliveryMethod'] as String? ?? 'meeting_point',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'SAR',
      status: json['status'] as String? ?? 'pending_carrier_acceptance',
      senderPhotos: List<String>.from(json['senderPhotos'] ?? []),
      pickupPhotos: List<String>.from(json['pickupPhotos'] ?? []),
      deliveryPhotos: List<String>.from(json['deliveryPhotos'] ?? []),
      pickupVerificationCode: json['pickupVerificationCode'] as String?,
      deliveryVerificationCode: json['deliveryVerificationCode'] as String?,
      pickupVerifiedAt: json['pickupVerifiedAt'] != null
          ? DateParser.parse(json['pickupVerifiedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateParser.parse(json['deliveredAt'])
          : null,
      createdAt: DateParser.parse(json['createdAt']),
      updatedAt: DateParser.parse(json['updatedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      rejectedBy: json['rejectedBy'] as String?,
      rejectedAt: json['rejectedAt'] != null
          ? DateParser.parse(json['rejectedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'qrCodeValue': qrCodeValue,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      if (senderSnapshot != null) 'senderSnapshot': senderSnapshot,
      if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
      if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverCountry': receiverCountry,
      'receiverProvince': receiverProvince,
      'receiverCity': receiverCity,
      'receiverDistrict': receiverDistrict,
      'receiverAddress': receiverAddress,
      'originCountryId': originCountryId,
      'originCountry': originCountry,
      'originProvinceId': originProvinceId,
      'originProvince': originProvince,
      'originCityId': originCityId,
      'originCity': originCity,
      'originAddress': originAddress,
      'destinationCountryId': destinationCountryId,
      'destinationCountry': destinationCountry,
      'destinationProvinceId': destinationProvinceId,
      'destinationProvince': destinationProvince,
      'destinationCityId': destinationCityId,
      'destinationCity': destinationCity,
      'destinationAddress': destinationAddress,
      'originDistrictId': originDistrictId,
      'originDistrict': originDistrict,
      'destinationDistrictId': destinationDistrictId,
      'destinationDistrict': destinationDistrict,
      'tripId': tripId,
      'carrierType': carrierType,
      'driverId': driverId,
      'companyId': companyId,
      'vehicleId': vehicleId,
      'carrierName': carrierName,
      'carrierRating': carrierRating,
      'carrierTripsCount': carrierTripsCount,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'category': category,
      'description': description,
      'declaredValue': declaredValue,
      'weight': weight,
      'size': size,
      'pieceCount': pieceCount,
      'isFragile': isFragile,
      'specialInstructions': specialInstructions,
      'pickupMethod': pickupMethod,
      'deliveryMethod': deliveryMethod,
      'price': price,
      'currency': currency,
      'status': status,
      'senderPhotos': senderPhotos,
      'pickupPhotos': pickupPhotos,
      'deliveryPhotos': deliveryPhotos,
      'pickupVerificationCode': pickupVerificationCode,
      'deliveryVerificationCode': deliveryVerificationCode,
      if (pickupVerifiedAt != null)
        'pickupVerifiedAt': pickupVerifiedAt!.toIso8601String(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (rejectedBy != null) 'rejectedBy': rejectedBy,
      if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    trackingNumber,
    qrCodeValue,
    senderId,
    senderName,
    senderPhone,
    receiverName,
    receiverPhone,
    receiverCountry,
    receiverProvince,
    receiverCity,
    receiverDistrict,
    receiverAddress,
    originCountryId,
    originCountry,
    originProvinceId,
    originProvince,
    originCityId,
    originCity,
    originAddress,
    destinationCountryId,
    destinationCountry,
    destinationProvinceId,
    destinationProvince,
    destinationCityId,
    destinationCity,
    destinationAddress,
    originDistrictId,
    originDistrict,
    destinationDistrictId,
    destinationDistrict,
    tripId,
    carrierType,
    driverId,
    companyId,
    vehicleId,
    carrierName,
    carrierRating,
    carrierTripsCount,
    vehicleType,
    vehicleModel,
    vehicleColor,
    category,
    description,
    declaredValue,
    weight,
    size,
    pieceCount,
    isFragile,
    specialInstructions,
    pickupMethod,
    deliveryMethod,
    price,
    currency,
    status,
    senderPhotos,
    pickupPhotos,
    deliveryPhotos,
    pickupVerificationCode,
    deliveryVerificationCode,
    pickupVerifiedAt,
    deliveredAt,
    createdAt,
    updatedAt,
    rejectionReason,
    rejectedBy,
    rejectedAt,
  ];
}
