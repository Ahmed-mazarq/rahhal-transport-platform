import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class PassengerProfile extends Equatable {
  final String uid;
  final List<String> favoriteDrivers;
  final List<Map<String, dynamic>> favoritePlaces;
  final double walletBalance;
  final int tripCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // active, blocked
  final String country;
  final String governorate;
  final String district;

  const PassengerProfile({
    required this.uid,
    this.favoriteDrivers = const [],
    this.favoritePlaces = const [],
    this.walletBalance = 0.0,
    this.tripCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.country = 'اليمن',
    this.governorate = '',
    this.district = '',
  });

  PassengerProfile copyWith({
    String? uid,
    List<String>? favoriteDrivers,
    List<Map<String, dynamic>>? favoritePlaces,
    double? walletBalance,
    int? tripCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? country,
    String? governorate,
    String? district,
  }) {
    return PassengerProfile(
      uid: uid ?? this.uid,
      favoriteDrivers: favoriteDrivers ?? this.favoriteDrivers,
      favoritePlaces: favoritePlaces ?? this.favoritePlaces,
      walletBalance: walletBalance ?? this.walletBalance,
      tripCount: tripCount ?? this.tripCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      country: country ?? this.country,
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
    );
  }

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      uid: json['uid'] as String? ?? '',
      favoriteDrivers:
          (json['favoriteDrivers'] as Iterable?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      favoritePlaces:
          (json['favoritePlaces'] as Iterable?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      tripCount: (json['tripCount'] as num?)?.toInt() ?? 0,
      createdAt: DateParser.parse(json['createdAt']),
      updatedAt: DateParser.parse(json['updatedAt']),
      status: json['status'] as String? ?? 'active',
      country: json['country'] as String? ?? 'اليمن',
      governorate: json['governorate'] as String? ?? '',
      district: json['district'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'favoriteDrivers': favoriteDrivers,
      'favoritePlaces': favoritePlaces,
      'walletBalance': walletBalance,
      'tripCount': tripCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'country': country,
      'governorate': governorate,
      'district': district,
    };
  }

  @override
  List<Object?> get props => [
    uid,
    favoriteDrivers,
    favoritePlaces,
    walletBalance,
    tripCount,
    createdAt,
    updatedAt,
    status,
    country,
    governorate,
    district,
  ];
}
