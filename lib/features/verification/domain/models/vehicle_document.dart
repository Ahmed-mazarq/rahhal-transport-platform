import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class VehicleDocument extends Equatable {
  final String id;
  final String vehicleId;
  final String type; // registration, insurance, inspection
  final String fileUrl;
  final DateTime expiryDate;
  final String status; // approved, pending, rejected

  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.fileUrl,
    required this.expiryDate,
    this.status = 'approved',
  });

  VehicleDocument copyWith({
    String? id,
    String? vehicleId,
    String? type,
    String? fileUrl,
    DateTime? expiryDate,
    String? status,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
    );
  }

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      expiryDate: DateParser.parse(json['expiryDate']),
      status: json['status'] as String? ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type,
      'fileUrl': fileUrl,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
    };
  }

  bool validate() {
    return id.isNotEmpty && vehicleId.isNotEmpty && type.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, vehicleId, type, fileUrl, expiryDate, status];
}
