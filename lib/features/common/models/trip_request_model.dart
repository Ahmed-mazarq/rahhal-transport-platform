import 'package:equatable/equatable.dart';

class TripRequestModel extends Equatable {
  final String id;
  final String passengerId;
  final String departureCityId;
  final String arrivalCityId;
  final DateTime desiredTime;
  final String status;

  const TripRequestModel({
    required this.id,
    required this.passengerId,
    required this.departureCityId,
    required this.arrivalCityId,
    required this.desiredTime,
    required this.status,
  });

  factory TripRequestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TripRequestModel(
      id: id,
      passengerId: data['passengerId']?.toString() ?? '',
      departureCityId: data['departureCityId']?.toString() ?? '',
      arrivalCityId: data['arrivalCityId']?.toString() ?? '',
      desiredTime:
          DateTime.tryParse(data['desiredTime']?.toString() ?? '') ??
          DateTime.now(),
      status: data['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'passengerId': passengerId,
      'departureCityId': departureCityId,
      'arrivalCityId': arrivalCityId,
      'desiredTime': desiredTime.toIso8601String(),
      'status': status,
    };
  }

  TripRequestModel copyWith({
    String? id,
    String? passengerId,
    String? departureCityId,
    String? arrivalCityId,
    DateTime? desiredTime,
    String? status,
  }) {
    return TripRequestModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      departureCityId: departureCityId ?? this.departureCityId,
      arrivalCityId: arrivalCityId ?? this.arrivalCityId,
      desiredTime: desiredTime ?? this.desiredTime,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    passengerId,
    departureCityId,
    arrivalCityId,
    desiredTime,
    status,
  ];
}
