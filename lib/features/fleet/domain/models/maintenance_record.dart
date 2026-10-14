import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class MaintenanceRecord extends Equatable {
  final String id;
  final String vehicleId;
  final String type; // oil_change, tires, engine, brakes, battery, general
  final DateTime datePerformed;
  final DateTime nextDueDate;
  final int mileageAtMaintenance;
  final double cost;
  final String notes;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.datePerformed,
    required this.nextDueDate,
    required this.mileageAtMaintenance,
    this.cost = 0.0,
    this.notes = '',
  });

  MaintenanceRecord copyWith({
    String? id,
    String? vehicleId,
    String? type,
    DateTime? datePerformed,
    DateTime? nextDueDate,
    int? mileageAtMaintenance,
    double? cost,
    String? notes,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      datePerformed: datePerformed ?? this.datePerformed,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      mileageAtMaintenance: mileageAtMaintenance ?? this.mileageAtMaintenance,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
    );
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      datePerformed: DateParser.parse(json['datePerformed']),
      nextDueDate: DateParser.parse(
        json['nextDueDate'],
        fallback: DateTime.now().add(const Duration(days: 90)),
      ),
      mileageAtMaintenance:
          (json['mileageAtMaintenance'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type,
      'datePerformed': datePerformed.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'mileageAtMaintenance': mileageAtMaintenance,
      'cost': cost,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    type,
    datePerformed,
    nextDueDate,
    mileageAtMaintenance,
    cost,
    notes,
  ];
}
