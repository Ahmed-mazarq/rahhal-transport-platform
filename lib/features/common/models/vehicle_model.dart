import 'package:equatable/equatable.dart';

class VehicleModel extends Equatable {
  final String id;
  final String? driverId;
  final String? companyId;
  final String plateNumber;
  final String model;
  final int year;
  final int capacity;
  final String make;
  final String color;
  final String type;
  final bool isDefault;
  final String photoUrl;
  final String localImagePath;
  final String futureStorageUrl;
  final int seatsCount;
  final String status;
  final String vin;
  final String registrationNumber;
  final String insuranceNumber;
  final String fuelType;
  final DateTime? registrationExpiry;
  final DateTime? insuranceExpiry;
  final double rating;
  final int tripCount;
  final DateTime? lastTripDate;

  const VehicleModel({
    required this.id,
    this.driverId,
    this.companyId,
    required this.plateNumber,
    required this.model,
    required this.year,
    required this.capacity,
    this.make = '',
    this.color = '',
    this.type = 'Sedan',
    this.isDefault = false,
    this.photoUrl = '',
    this.localImagePath = '',
    this.futureStorageUrl = '',
    this.seatsCount = 4,
    this.status = 'Pending',
    this.vin = '',
    this.registrationNumber = '',
    this.insuranceNumber = '',
    this.fuelType = 'بنزين',
    this.registrationExpiry,
    this.insuranceExpiry,
    this.rating = 5.0,
    this.tripCount = 0,
    this.lastTripDate,
  });

  factory VehicleModel.fromFirestore(Map<String, dynamic> data, String id) {
    return VehicleModel(
      id: id,
      driverId: data['driverId']?.toString(),
      companyId: data['companyId']?.toString(),
      plateNumber: data['plateNumber']?.toString() ?? '',
      model: data['model']?.toString() ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      make: data['make']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Sedan',
      isDefault: data['isDefault'] as bool? ?? false,
      photoUrl: data['photoUrl']?.toString() ?? '',
      localImagePath: data['localImagePath']?.toString() ?? '',
      futureStorageUrl: data['futureStorageUrl']?.toString() ?? '',
      seatsCount:
          (data['seatsCount'] as num?)?.toInt() ??
          (data['capacity'] as num?)?.toInt() ??
          4,
      status: data['status']?.toString() ?? 'Pending',
      vin: data['vin']?.toString() ?? '',
      registrationNumber: data['registrationNumber']?.toString() ?? '',
      insuranceNumber: data['insuranceNumber']?.toString() ?? '',
      fuelType: data['fuelType']?.toString() ?? 'بنزين',
      registrationExpiry: data['registrationExpiry'] != null
          ? DateTime.tryParse(data['registrationExpiry'].toString())
          : null,
      insuranceExpiry: data['insuranceExpiry'] != null
          ? DateTime.tryParse(data['insuranceExpiry'].toString())
          : null,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      tripCount: (data['tripCount'] as num?)?.toInt() ?? 0,
      lastTripDate: data['lastTripDate'] != null
          ? DateTime.tryParse(data['lastTripDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'companyId': companyId,
      'plateNumber': plateNumber,
      'model': model,
      'year': year,
      'capacity': capacity,
      'make': make,
      'color': color,
      'type': type,
      'isDefault': isDefault,
      'photoUrl': photoUrl,
      'localImagePath': localImagePath,
      'futureStorageUrl': futureStorageUrl,
      'seatsCount': seatsCount,
      'status': status,
      'vin': vin,
      'registrationNumber': registrationNumber,
      'insuranceNumber': insuranceNumber,
      'fuelType': fuelType,
      'registrationExpiry': registrationExpiry?.toIso8601String(),
      'insuranceExpiry': insuranceExpiry?.toIso8601String(),
      'rating': rating,
      'tripCount': tripCount,
      'lastTripDate': lastTripDate?.toIso8601String(),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? driverId,
    String? companyId,
    String? plateNumber,
    String? model,
    int? year,
    int? capacity,
    String? make,
    String? color,
    String? type,
    bool? isDefault,
    String? photoUrl,
    String? localImagePath,
    String? futureStorageUrl,
    int? seatsCount,
    String? status,
    String? vin,
    String? registrationNumber,
    String? insuranceNumber,
    String? fuelType,
    DateTime? registrationExpiry,
    DateTime? insuranceExpiry,
    double? rating,
    int? tripCount,
    DateTime? lastTripDate,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      companyId: companyId ?? this.companyId,
      plateNumber: plateNumber ?? this.plateNumber,
      model: model ?? this.model,
      year: year ?? this.year,
      capacity: capacity ?? this.capacity,
      make: make ?? this.make,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      photoUrl: photoUrl ?? this.photoUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      futureStorageUrl: futureStorageUrl ?? this.futureStorageUrl,
      seatsCount: seatsCount ?? this.seatsCount,
      status: status ?? this.status,
      vin: vin ?? this.vin,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      fuelType: fuelType ?? this.fuelType,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      rating: rating ?? this.rating,
      tripCount: tripCount ?? this.tripCount,
      lastTripDate: lastTripDate ?? this.lastTripDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    companyId,
    plateNumber,
    model,
    year,
    capacity,
    make,
    color,
    type,
    isDefault,
    photoUrl,
    localImagePath,
    futureStorageUrl,
    seatsCount,
    status,
    vin,
    registrationNumber,
    insuranceNumber,
    fuelType,
    registrationExpiry,
    insuranceExpiry,
    rating,
    tripCount,
    lastTripDate,
  ];
}
