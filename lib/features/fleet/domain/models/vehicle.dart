import 'package:equatable/equatable.dart';
import 'maintenance_record.dart';
export 'maintenance_record.dart';

class Vehicle extends Equatable {
  final String id;
  final String driverId;
  final String make;
  final String model;
  final int year;
  final String color;
  final String plateNumber;
  final String type; // e.g. Minibus, Sedan, SUV, Bus, Van, Pickup
  final bool isDefault;
  final String photoUrl; // main thumbnail
  final List<String> additionalPhotos; // front, rear, side, interior
  final int seatsCount;
  final String
  status; // Available, In Service, Maintenance, Inactive, Blocked, Pending
  final String vin;
  final String registrationNumber;
  final String insuranceNumber;
  final List<MaintenanceRecord> maintenanceRecords;
  final int currentMileage;
  final String fuelType;
  final DateTime? registrationExpiry;
  final DateTime? insuranceExpiry;
  final double rating;
  final int tripCount;
  final DateTime? lastTripDate;

  const Vehicle({
    required this.id,
    required this.driverId,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plateNumber,
    required this.type,
    this.isDefault = false,
    this.photoUrl = '',
    this.additionalPhotos = const [],
    this.seatsCount = 4,
    this.status = 'Pending',
    this.vin = '',
    this.registrationNumber = '',
    this.insuranceNumber = '',
    this.maintenanceRecords = const [],
    this.currentMileage = 0,
    this.fuelType = 'بنزين',
    this.registrationExpiry,
    this.insuranceExpiry,
    this.rating = 5.0,
    this.tripCount = 0,
    this.lastTripDate,
  });

  Vehicle copyWith({
    String? id,
    String? driverId,
    String? make,
    String? model,
    int? year,
    String? color,
    String? plateNumber,
    String? type,
    bool? isDefault,
    String? photoUrl,
    List<String>? additionalPhotos,
    int? seatsCount,
    String? status,
    String? vin,
    String? registrationNumber,
    String? insuranceNumber,
    List<MaintenanceRecord>? maintenanceRecords,
    int? currentMileage,
    String? fuelType,
    DateTime? registrationExpiry,
    DateTime? insuranceExpiry,
    double? rating,
    int? tripCount,
    DateTime? lastTripDate,
  }) {
    return Vehicle(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      photoUrl: photoUrl ?? this.photoUrl,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
      seatsCount: seatsCount ?? this.seatsCount,
      status: status ?? this.status,
      vin: vin ?? this.vin,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      maintenanceRecords: maintenanceRecords ?? this.maintenanceRecords,
      currentMileage: currentMileage ?? this.currentMileage,
      fuelType: fuelType ?? this.fuelType,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      rating: rating ?? this.rating,
      tripCount: tripCount ?? this.tripCount,
      lastTripDate: lastTripDate ?? this.lastTripDate,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 2020,
      color: json['color'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      type: json['type'] as String? ?? 'Sedan',
      isDefault: json['isDefault'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String? ?? '',
      additionalPhotos:
          (json['additionalPhotos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      seatsCount: (json['seatsCount'] as num?)?.toInt() ?? 4,
      status: json['status'] as String? ?? 'Pending',
      vin: json['vin'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      insuranceNumber: json['insuranceNumber'] as String? ?? '',
      maintenanceRecords:
          (json['maintenanceRecords'] as List<dynamic>?)
              ?.map(
                (e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      currentMileage: (json['currentMileage'] as num?)?.toInt() ?? 0,
      fuelType: json['fuelType'] as String? ?? 'بنزين',
      registrationExpiry: json['registrationExpiry'] != null
          ? DateTime.tryParse(json['registrationExpiry'].toString())
          : null,
      insuranceExpiry: json['insuranceExpiry'] != null
          ? DateTime.tryParse(json['insuranceExpiry'].toString())
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      tripCount: (json['tripCount'] as num?)?.toInt() ?? 0,
      lastTripDate: json['lastTripDate'] != null
          ? DateTime.tryParse(json['lastTripDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'plateNumber': plateNumber,
      'type': type,
      'isDefault': isDefault,
      'photoUrl': photoUrl,
      'additionalPhotos': additionalPhotos,
      'seatsCount': seatsCount,
      'status': status,
      'vin': vin,
      'registrationNumber': registrationNumber,
      'insuranceNumber': insuranceNumber,
      'maintenanceRecords': maintenanceRecords.map((e) => e.toJson()).toList(),
      'currentMileage': currentMileage,
      'fuelType': fuelType,
      'registrationExpiry': registrationExpiry?.toIso8601String(),
      'insuranceExpiry': insuranceExpiry?.toIso8601String(),
      'rating': rating,
      'tripCount': tripCount,
      'lastTripDate': lastTripDate?.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty &&
        driverId.isNotEmpty &&
        plateNumber.isNotEmpty &&
        type.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    make,
    model,
    year,
    color,
    plateNumber,
    type,
    isDefault,
    photoUrl,
    additionalPhotos,
    seatsCount,
    status,
    vin,
    registrationNumber,
    insuranceNumber,
    maintenanceRecords,
    currentMileage,
    fuelType,
    registrationExpiry,
    insuranceExpiry,
    rating,
    tripCount,
    lastTripDate,
  ];
}
