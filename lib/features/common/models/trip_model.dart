import 'package:equatable/equatable.dart';

class TripModel extends Equatable {
  final String id;
  final String driverId;
  final String? companyId;
  final String vehicleId;
  final String departureCityId;
  final String arrivalCityId;
  final DateTime departureTime;
  final double price;
  final int availableSeats;
  final String status;

  const TripModel({
    required this.id,
    required this.driverId,
    this.companyId,
    required this.vehicleId,
    required this.departureCityId,
    required this.arrivalCityId,
    required this.departureTime,
    required this.price,
    required this.availableSeats,
    required this.status,
  });

  factory TripModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TripModel(
      id: id,
      driverId: data['driverId']?.toString() ?? '',
      companyId: data['companyId']?.toString(),
      vehicleId: data['vehicleId']?.toString() ?? '',
      departureCityId: data['departureCityId']?.toString() ?? '',
      arrivalCityId: data['arrivalCityId']?.toString() ?? '',
      departureTime:
          DateTime.tryParse(data['departureTime']?.toString() ?? '') ??
          DateTime.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      status: data['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'companyId': companyId,
      'vehicleId': vehicleId,
      'departureCityId': departureCityId,
      'arrivalCityId': arrivalCityId,
      'departureTime': departureTime.toIso8601String(),
      'price': price,
      'availableSeats': availableSeats,
      'status': status,
    };
  }

  TripModel copyWith({
    String? id,
    String? driverId,
    String? companyId,
    String? vehicleId,
    String? departureCityId,
    String? arrivalCityId,
    DateTime? departureTime,
    double? price,
    int? availableSeats,
    String? status,
  }) {
    return TripModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      departureCityId: departureCityId ?? this.departureCityId,
      arrivalCityId: arrivalCityId ?? this.arrivalCityId,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      availableSeats: availableSeats ?? this.availableSeats,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    companyId,
    vehicleId,
    departureCityId,
    arrivalCityId,
    departureTime,
    price,
    availableSeats,
    status,
  ];
}
