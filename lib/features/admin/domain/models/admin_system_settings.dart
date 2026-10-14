import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSystemSettings {
  final String appName;
  final String timezone;
  final String currency;

  final bool maintenanceMode;
  final String maintenanceMessageAr;
  final String maintenanceMessageEn;
  final DateTime? maintenanceUntil;
  final bool allowAdminBypass;

  final String supportEmail;
  final String supportPhone;
  final String supportWhatsapp;

  final DateTime? updatedAt;
  final String? updatedBy;
  final int schemaVersion;

  AdminSystemSettings({
    required this.appName,
    required this.timezone,
    required this.currency,
    required this.maintenanceMode,
    required this.maintenanceMessageAr,
    required this.maintenanceMessageEn,
    this.maintenanceUntil,
    required this.allowAdminBypass,
    required this.supportEmail,
    required this.supportPhone,
    required this.supportWhatsapp,
    this.updatedAt,
    this.updatedBy,
    required this.schemaVersion,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory AdminSystemSettings.fromMap(Map<String, dynamic> map) {
    return AdminSystemSettings(
      appName: map['appName'] as String? ?? 'رحّال',
      timezone: map['timezone'] as String? ?? 'Asia/Riyadh',
      currency: map['currency'] as String? ?? 'SAR',

      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      maintenanceMessageAr:
          map['maintenanceMessageAr'] as String? ??
          'نظام رحّال تحت الصيانة حالياً',
      maintenanceMessageEn:
          map['maintenanceMessageEn'] as String? ??
          'Rahhal system is currently under maintenance',
      maintenanceUntil: _parseDate(map['maintenanceUntil']),
      allowAdminBypass: map['allowAdminBypass'] as bool? ?? true,

      supportEmail: map['supportEmail'] as String? ?? '',
      supportPhone: map['supportPhone'] as String? ?? '',
      supportWhatsapp: map['supportWhatsapp'] as String? ?? '',

      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
      schemaVersion: map['schemaVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'timezone': timezone,
      'currency': currency,

      'maintenanceMode': maintenanceMode,
      'maintenanceMessageAr': maintenanceMessageAr,
      'maintenanceMessageEn': maintenanceMessageEn,
      'maintenanceUntil': maintenanceUntil != null
          ? Timestamp.fromDate(maintenanceUntil!)
          : null,
      'allowAdminBypass': allowAdminBypass,

      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'supportWhatsapp': supportWhatsapp,

      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
      'schemaVersion': 2,
    };
  }

  AdminSystemSettings copyWith({
    String? appName,
    String? timezone,
    String? currency,
    bool? maintenanceMode,
    String? maintenanceMessageAr,
    String? maintenanceMessageEn,
    DateTime? maintenanceUntil,
    bool? allowAdminBypass,
    String? supportEmail,
    String? supportPhone,
    String? supportWhatsapp,
    DateTime? updatedAt,
    String? updatedBy,
    int? schemaVersion,
  }) {
    return AdminSystemSettings(
      appName: appName ?? this.appName,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessageAr: maintenanceMessageAr ?? this.maintenanceMessageAr,
      maintenanceMessageEn: maintenanceMessageEn ?? this.maintenanceMessageEn,
      maintenanceUntil: maintenanceUntil ?? this.maintenanceUntil,
      allowAdminBypass: allowAdminBypass ?? this.allowAdminBypass,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      supportWhatsapp: supportWhatsapp ?? this.supportWhatsapp,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  AdminSystemSettings clearMaintenanceUntil() {
    return AdminSystemSettings(
      appName: appName,
      timezone: timezone,
      currency: currency,
      maintenanceMode: maintenanceMode,
      maintenanceMessageAr: maintenanceMessageAr,
      maintenanceMessageEn: maintenanceMessageEn,
      maintenanceUntil: null,
      allowAdminBypass: allowAdminBypass,
      supportEmail: supportEmail,
      supportPhone: supportPhone,
      supportWhatsapp: supportWhatsapp,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      schemaVersion: schemaVersion,
    );
  }
}
