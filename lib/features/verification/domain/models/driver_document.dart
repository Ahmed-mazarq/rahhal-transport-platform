import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class DriverDocument extends Equatable {
  final String id;
  final String driverId;
  final String
  type; // national_id, driving_license, residence_permit, insurance
  final String fileUrl;
  final DateTime expiryDate;
  final String status; // approved, pending, rejected

  const DriverDocument({
    required this.id,
    required this.driverId,
    required this.type,
    required this.fileUrl,
    required this.expiryDate,
    this.status =
        'approved', // Default auto-approve for simulated prod demo flow
  });

  DriverDocument copyWith({
    String? id,
    String? driverId,
    String? type,
    String? fileUrl,
    DateTime? expiryDate,
    String? status,
  }) {
    return DriverDocument(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
    );
  }

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      expiryDate: DateParser.parse(json['expiryDate']),
      status: json['status'] as String? ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'type': type,
      'fileUrl': fileUrl,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
    };
  }

  bool validate() {
    return id.isNotEmpty && driverId.isNotEmpty && type.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, driverId, type, fileUrl, expiryDate, status];
}
