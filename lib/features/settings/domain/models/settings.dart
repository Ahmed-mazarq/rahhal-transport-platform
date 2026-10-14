import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final String id;
  final bool enableNotifications;
  final bool enableBookingNotifications;
  final bool enableTripNotifications;
  final bool enableWalletNotifications;
  final bool enableSupportNotifications;
  final bool enableOffersNotifications;
  final bool enableSystemNotifications;

  final bool enableDarkMode;
  final double baseFare;
  final double pricePerKm;
  final String activeLanguage;

  const Settings({
    required this.id,
    this.enableNotifications = true,
    this.enableBookingNotifications = true,
    this.enableTripNotifications = true,
    this.enableWalletNotifications = true,
    this.enableSupportNotifications = true,
    this.enableOffersNotifications = true,
    this.enableSystemNotifications = true,
    this.enableDarkMode = false,
    required this.baseFare,
    required this.pricePerKm,
    this.activeLanguage = 'ar',
  });

  Settings copyWith({
    String? id,
    bool? enableNotifications,
    bool? enableBookingNotifications,
    bool? enableTripNotifications,
    bool? enableWalletNotifications,
    bool? enableSupportNotifications,
    bool? enableOffersNotifications,
    bool? enableSystemNotifications,
    bool? enableDarkMode,
    double? baseFare,
    double? pricePerKm,
    String? activeLanguage,
  }) {
    return Settings(
      id: id ?? this.id,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableBookingNotifications:
          enableBookingNotifications ?? this.enableBookingNotifications,
      enableTripNotifications:
          enableTripNotifications ?? this.enableTripNotifications,
      enableWalletNotifications:
          enableWalletNotifications ?? this.enableWalletNotifications,
      enableSupportNotifications:
          enableSupportNotifications ?? this.enableSupportNotifications,
      enableOffersNotifications:
          enableOffersNotifications ?? this.enableOffersNotifications,
      enableSystemNotifications:
          enableSystemNotifications ?? this.enableSystemNotifications,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      baseFare: baseFare ?? this.baseFare,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      activeLanguage: activeLanguage ?? this.activeLanguage,
    );
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      id: json['id'] as String? ?? '',
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableBookingNotifications:
          json['enableBookingNotifications'] as bool? ?? true,
      enableTripNotifications: json['enableTripNotifications'] as bool? ?? true,
      enableWalletNotifications:
          json['enableWalletNotifications'] as bool? ?? true,
      enableSupportNotifications:
          json['enableSupportNotifications'] as bool? ?? true,
      enableOffersNotifications:
          json['enableOffersNotifications'] as bool? ?? true,
      enableSystemNotifications:
          json['enableSystemNotifications'] as bool? ?? true,
      enableDarkMode: json['enableDarkMode'] as bool? ?? false,
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 5.0,
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble() ?? 1.5,
      activeLanguage: json['activeLanguage'] as String? ?? 'ar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enableNotifications': enableNotifications,
      'enableBookingNotifications': enableBookingNotifications,
      'enableTripNotifications': enableTripNotifications,
      'enableWalletNotifications': enableWalletNotifications,
      'enableSupportNotifications': enableSupportNotifications,
      'enableOffersNotifications': enableOffersNotifications,
      'enableSystemNotifications': enableSystemNotifications,
      'enableDarkMode': enableDarkMode,
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'activeLanguage': activeLanguage,
    };
  }

  bool validate() {
    return id.isNotEmpty && baseFare >= 0 && pricePerKm >= 0;
  }

  @override
  List<Object?> get props => [
    id,
    enableNotifications,
    enableBookingNotifications,
    enableTripNotifications,
    enableWalletNotifications,
    enableSupportNotifications,
    enableOffersNotifications,
    enableSystemNotifications,
    enableDarkMode,
    baseFare,
    pricePerKm,
    activeLanguage,
  ];
}
