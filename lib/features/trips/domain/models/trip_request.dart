import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class TripRequest extends Equatable {
  final String id;
  final String passengerId;
  final String startLocationName;
  final String endLocationName;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final double estimatedPrice;
  final String status; // e.g. pending, accepted, rejected, cancelled
  final DateTime createdAt;

  const TripRequest({
    required this.id,
    required this.passengerId,
    required this.startLocationName,
    required this.endLocationName,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.estimatedPrice,
    required this.status,
    required this.createdAt,
  });

  TripRequest copyWith({
    String? id,
    String? passengerId,
    String? startLocationName,
    String? endLocationName,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    double? estimatedPrice,
    String? status,
    DateTime? createdAt,
  }) {
    return TripRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      startLocationName: startLocationName ?? this.startLocationName,
      endLocationName: endLocationName ?? this.endLocationName,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TripRequest.fromJson(Map<String, dynamic> json) {
    return TripRequest(
      id: json['id'] as String? ?? '',
      passengerId: json['passengerId'] as String? ?? '',
      startLocationName: json['startLocationName'] as String? ?? '',
      endLocationName: json['endLocationName'] as String? ?? '',
      startLatitude: (json['startLatitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (json['startLongitude'] as num?)?.toDouble() ?? 0.0,
      endLatitude: (json['endLatitude'] as num?)?.toDouble() ?? 0.0,
      endLongitude: (json['endLongitude'] as num?)?.toDouble() ?? 0.0,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'startLocationName': startLocationName,
      'endLocationName': endLocationName,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'estimatedPrice': estimatedPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty &&
        passengerId.isNotEmpty &&
        startLocationName.isNotEmpty &&
        endLocationName.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    id,
    passengerId,
    startLocationName,
    endLocationName,
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
    estimatedPrice,
    status,
    createdAt,
  ];
}
