import 'package:equatable/equatable.dart';

class SettingsModel extends Equatable {
  final String id;
  final String appVersion;
  final bool maintenanceMode;
  final double taxRate;

  const SettingsModel({
    required this.id,
    required this.appVersion,
    required this.maintenanceMode,
    required this.taxRate,
  });

  factory SettingsModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SettingsModel(
      id: id,
      appVersion: data['appVersion']?.toString() ?? '',
      maintenanceMode: data['maintenanceMode'] as bool? ?? false,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appVersion': appVersion,
      'maintenanceMode': maintenanceMode,
      'taxRate': taxRate,
    };
  }

  SettingsModel copyWith({
    String? id,
    String? appVersion,
    bool? maintenanceMode,
    double? taxRate,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      appVersion: appVersion ?? this.appVersion,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  @override
  List<Object?> get props => [id, appVersion, maintenanceMode, taxRate];
}
