import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'ar', 'en'
  final bool bookingNotifications;
  final bool systemNotifications;
  final bool offersNotifications;
  final bool biometricEnabled;
  final bool locationEnabled;
  final String accountStatus; // 'active', 'deleted'
  final DateTime? deleteRequestedAt;
  final DateTime? lastUpdated;
  final DateTime? createdAt;

  const AppSettings({
    this.theme = 'system',
    this.language = 'ar',
    this.bookingNotifications = true,
    this.systemNotifications = true,
    this.offersNotifications = true,
    this.biometricEnabled = false,
    this.locationEnabled = false,
    this.accountStatus = 'active',
    this.deleteRequestedAt,
    this.lastUpdated,
    this.createdAt,
  });

  AppSettings copyWith({
    String? theme,
    String? language,
    bool? bookingNotifications,
    bool? systemNotifications,
    bool? offersNotifications,
    bool? biometricEnabled,
    bool? locationEnabled,
    String? accountStatus,
    DateTime? deleteRequestedAt,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      bookingNotifications: bookingNotifications ?? this.bookingNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      offersNotifications: offersNotifications ?? this.offersNotifications,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      accountStatus: accountStatus ?? this.accountStatus,
      deleteRequestedAt: deleteRequestedAt ?? this.deleteRequestedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'ar',
      bookingNotifications: json['bookingNotifications'] as bool? ?? true,
      systemNotifications: json['systemNotifications'] as bool? ?? true,
      offersNotifications: json['offersNotifications'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      locationEnabled: json['locationEnabled'] as bool? ?? false,
      accountStatus: json['accountStatus'] as String? ?? 'active',
      deleteRequestedAt: json['deleteRequestedAt'] != null
          ? DateTime.tryParse(json['deleteRequestedAt'].toString())
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'bookingNotifications': bookingNotifications,
      'systemNotifications': systemNotifications,
      'offersNotifications': offersNotifications,
      'biometricEnabled': biometricEnabled,
      'locationEnabled': locationEnabled,
      'accountStatus': accountStatus,
      'deleteRequestedAt': deleteRequestedAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    theme,
    language,
    bookingNotifications,
    systemNotifications,
    offersNotifications,
    biometricEnabled,
    locationEnabled,
    accountStatus,
    deleteRequestedAt,
    lastUpdated,
    createdAt,
  ];
}
