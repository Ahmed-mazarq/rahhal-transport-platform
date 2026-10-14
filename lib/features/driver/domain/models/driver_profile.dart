import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';
import 'driver_stats.dart';
import 'working_area.dart';
import 'payment_method.dart';
import 'driver_document.dart';

class DriverProfile extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String profileImage;
  final String country;
  final String workingCountry;
  final String
  status; // Pending Review, Approved, Need Documents, Suspended, Blocked
  final String verificationStatus;
  final double rating;
  final int completedTrips;
  final int cancelledTrips;
  final DateTime joinedDate;
  final DateTime lastOnline;
  final bool isOnline;
  final List<String> vehicleIds;
  final String? primaryVehicleId;
  final List<WorkingArea> workingAreas;
  final List<PaymentMethod> paymentMethods;
  final List<DriverDocument> documents; // Updated to use DriverDocument model
  final DriverStats statistics;
  final Map<String, dynamic> settings;

  // New fields for the premium profile
  final String bio;
  final List<String> languages;
  final String emergencyContact;
  final double commitmentPercentage;
  final double cancellationPercentage;
  final int totalPassengers;
  final int avgResponseTimeMins; // Average Response Time in minutes
  final int? profileImageUpdatedAt;

  // Raw Document Fields
  final String? passportNumber;
  final String? passportExpiry;
  final String? licenseNumber;
  final String? licenseType;
  final String? licenseCountry;
  final String? licenseIssueDate;
  final String? licenseExpiryDate;
  final String? vehicleType;
  final String? vehicleManufacturer;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? plateNumber;
  final String? vin;
  final String? registrationNumber;
  final String? registrationExpiry;
  final String? insuranceNumber;
  final String? insuranceExpiry;

  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.profileImage = '',
    this.country = '',
    this.workingCountry = '',
    this.status = 'Pending Review',
    this.verificationStatus = 'pending',
    this.rating = 5.0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    required this.joinedDate,
    required this.lastOnline,
    this.isOnline = false,
    this.vehicleIds = const [],
    this.primaryVehicleId,
    this.workingAreas = const [],
    this.paymentMethods = const [],
    this.documents = const [],
    this.statistics = const DriverStats(),
    this.settings = const {},

    this.bio = '',
    this.languages = const ['Arabic'],
    this.emergencyContact = '',
    this.commitmentPercentage = 100.0,
    this.cancellationPercentage = 0.0,
    this.totalPassengers = 0,
    this.avgResponseTimeMins = 5,
    this.profileImageUpdatedAt,

    // Document Fields
    this.passportNumber,
    this.passportExpiry,
    this.licenseNumber,
    this.licenseType,
    this.licenseCountry,
    this.licenseIssueDate,
    this.licenseExpiryDate,
    this.vehicleType,
    this.vehicleManufacturer,
    this.vehicleModel,
    this.vehicleYear,
    this.plateNumber,
    this.vin,
    this.registrationNumber,
    this.registrationExpiry,
    this.insuranceNumber,
    this.insuranceExpiry,
  });

  bool get isApproved {
    final normalizedStatus = status.trim().toLowerCase();
    final normalizedVerification = verificationStatus.trim().toLowerCase();
    return normalizedStatus == 'approved' ||
        normalizedVerification == 'approved' ||
        normalizedVerification == 'verified';
  }

  DriverProfile copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    String? country,
    String? workingCountry,
    String? status,
    String? verificationStatus,
    double? rating,
    int? completedTrips,
    int? cancelledTrips,
    DateTime? joinedDate,
    DateTime? lastOnline,
    bool? isOnline,
    List<String>? vehicleIds,
    String? primaryVehicleId,
    List<WorkingArea>? workingAreas,
    List<PaymentMethod>? paymentMethods,
    List<DriverDocument>? documents,
    DriverStats? statistics,
    Map<String, dynamic>? settings,
    String? bio,
    List<String>? languages,
    String? emergencyContact,
    double? commitmentPercentage,
    double? cancellationPercentage,
    int? totalPassengers,
    int? avgResponseTimeMins,
    int? profileImageUpdatedAt,
    String? passportNumber,
    String? passportExpiry,
    String? licenseNumber,
    String? licenseType,
    String? licenseCountry,
    String? licenseIssueDate,
    String? licenseExpiryDate,
    String? vehicleType,
    String? vehicleManufacturer,
    String? vehicleModel,
    String? vehicleYear,
    String? plateNumber,
    String? vin,
    String? registrationNumber,
    String? registrationExpiry,
    String? insuranceNumber,
    String? insuranceExpiry,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      country: country ?? this.country,
      workingCountry: workingCountry ?? this.workingCountry,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      joinedDate: joinedDate ?? this.joinedDate,
      lastOnline: lastOnline ?? this.lastOnline,
      isOnline: isOnline ?? this.isOnline,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      primaryVehicleId: primaryVehicleId ?? this.primaryVehicleId,
      workingAreas: workingAreas ?? this.workingAreas,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      documents: documents ?? this.documents,
      statistics: statistics ?? this.statistics,
      settings: settings ?? this.settings,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      commitmentPercentage: commitmentPercentage ?? this.commitmentPercentage,
      cancellationPercentage:
          cancellationPercentage ?? this.cancellationPercentage,
      totalPassengers: totalPassengers ?? this.totalPassengers,
      avgResponseTimeMins: avgResponseTimeMins ?? this.avgResponseTimeMins,
      profileImageUpdatedAt:
          profileImageUpdatedAt ?? this.profileImageUpdatedAt,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseType: licenseType ?? this.licenseType,
      licenseCountry: licenseCountry ?? this.licenseCountry,
      licenseIssueDate: licenseIssueDate ?? this.licenseIssueDate,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleManufacturer: vehicleManufacturer ?? this.vehicleManufacturer,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      plateNumber: plateNumber ?? this.plateNumber,
      vin: vin ?? this.vin,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
    );
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().trim() ?? 'Pending Review';
    final rawVerificationStatus = json['verificationStatus']?.toString().trim();

    // Safely fallback verificationStatus to status if absent
    final computedVerificationStatus =
        (rawVerificationStatus != null && rawVerificationStatus.isNotEmpty)
        ? rawVerificationStatus
        : rawStatus.toLowerCase();

    return DriverProfile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profileImage: json['profileImage'] as String? ?? '',
      country: json['country'] as String? ?? '',
      workingCountry: json['workingCountry'] as String? ?? '',
      status: rawStatus,
      verificationStatus: computedVerificationStatus,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
      cancelledTrips: (json['cancelledTrips'] as num?)?.toInt() ?? 0,
      joinedDate: DateParser.parse(json['joinedDate']),
      lastOnline: DateParser.parse(json['lastOnline']),
      isOnline: json['isOnline'] as bool? ?? false,
      vehicleIds: () {
        final vIds = json['vehicleIds'];
        if (vIds is List) return vIds.map((e) => e.toString()).toList();
        if (vIds is String) return [vIds];
        return <String>[];
      }(),
      primaryVehicleId: json['primaryVehicleId'] as String?,
      workingAreas: () {
        final wa = json['workingAreas'];
        if (wa is List) {
          return wa
              .map((e) {
                if (e is Map) {
                  return WorkingArea.fromJson(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<WorkingArea>()
              .toList();
        }
        return <WorkingArea>[];
      }(),
      paymentMethods: () {
        final pm = json['paymentMethods'];
        if (pm is List) {
          return pm
              .map((e) {
                if (e is Map) {
                  return PaymentMethod.fromJson(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<PaymentMethod>()
              .toList();
        }
        return <PaymentMethod>[];
      }(),
      documents: () {
        final docs = json['documents'];
        if (docs is List) {
          return docs.map((e) {
            if (e is String) {
              return DriverDocument(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: 'unknown',
                documentNumber: '',
                issueDate: DateTime.now(),
                expiryDate: DateTime.now(),
                photoUrl: e,
              );
            }
            if (e is Map) {
              return DriverDocument.fromJson(Map<String, dynamic>.from(e));
            }
            return DriverDocument(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: 'unknown',
              documentNumber: '',
              issueDate: DateTime.now(),
              expiryDate: DateTime.now(),
              photoUrl: '',
            );
          }).toList();
        } else if (docs is Map) {
          return docs.entries.map((e) {
            final val = e.value;
            if (val is Map) {
              return DriverDocument(
                id: e.key.toString(),
                type: e.key.toString(),
                documentNumber: '',
                issueDate: DateTime.now(),
                expiryDate: DateTime.now(),
                photoUrl: val['url']?.toString() ?? '',
              );
            }
            return DriverDocument(
              id: e.key.toString(),
              type: e.key.toString(),
              documentNumber: '',
              issueDate: DateTime.now(),
              expiryDate: DateTime.now(),
              photoUrl: val.toString(),
            );
          }).toList();
        }
        return <DriverDocument>[];
      }(),
      statistics: json['statistics'] is Map
          ? DriverStats.fromJson(Map<String, dynamic>.from(json['statistics']))
          : const DriverStats(),
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'])
          : {},
      bio: json['bio'] as String? ?? '',
      languages: () {
        final lang = json['languages'];
        if (lang is List) return lang.map((e) => e.toString()).toList();
        if (lang is String) return [lang];
        return <String>['Arabic'];
      }(),
      emergencyContact: json['emergencyContact'] as String? ?? '',
      commitmentPercentage:
          (json['commitmentPercentage'] as num?)?.toDouble() ?? 100.0,
      cancellationPercentage:
          (json['cancellationPercentage'] as num?)?.toDouble() ?? 0.0,
      totalPassengers: (json['totalPassengers'] as num?)?.toInt() ?? 0,
      avgResponseTimeMins: (json['avgResponseTimeMins'] as num?)?.toInt() ?? 5,
      profileImageUpdatedAt: (json['profileImageUpdatedAt'] as num?)?.toInt(),
      passportNumber: json['passportNumber']?.toString(),
      passportExpiry: json['passportExpiry']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      licenseType: json['licenseType']?.toString(),
      licenseCountry: json['licenseCountry']?.toString(),
      licenseIssueDate: json['licenseIssueDate']?.toString(),
      licenseExpiryDate: json['licenseExpiryDate']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      vehicleManufacturer: json['vehicleManufacturer']?.toString(),
      vehicleModel: json['vehicleModel']?.toString(),
      vehicleYear: json['vehicleYear']?.toString(),
      plateNumber: json['plateNumber']?.toString(),
      vin: json['vin']?.toString(),
      registrationNumber: json['registrationNumber']?.toString(),
      registrationExpiry: json['registrationExpiry']?.toString(),
      insuranceNumber: json['insuranceNumber']?.toString(),
      insuranceExpiry: json['insuranceExpiry']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'country': country,
      'workingCountry': workingCountry,
      'status': status,
      'verificationStatus': verificationStatus,
      'rating': rating,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'joinedDate': joinedDate.toIso8601String(),
      'lastOnline': lastOnline.toIso8601String(),
      'isOnline': isOnline,
      'vehicleIds': vehicleIds,
      'primaryVehicleId': primaryVehicleId,
      'workingAreas': workingAreas.map((e) => e.toJson()).toList(),
      'paymentMethods': paymentMethods.map((e) => e.toJson()).toList(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'statistics': statistics.toJson(),
      'settings': settings,
      'bio': bio,
      'languages': languages,
      'emergencyContact': emergencyContact,
      'commitmentPercentage': commitmentPercentage,
      'cancellationPercentage': cancellationPercentage,
      'totalPassengers': totalPassengers,
      'avgResponseTimeMins': avgResponseTimeMins,
      if (profileImageUpdatedAt != null)
        'profileImageUpdatedAt': profileImageUpdatedAt,
      if (passportNumber != null) 'passportNumber': passportNumber,
      if (passportExpiry != null) 'passportExpiry': passportExpiry,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (licenseType != null) 'licenseType': licenseType,
      if (licenseCountry != null) 'licenseCountry': licenseCountry,
      if (licenseIssueDate != null) 'licenseIssueDate': licenseIssueDate,
      if (licenseExpiryDate != null) 'licenseExpiryDate': licenseExpiryDate,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (vehicleManufacturer != null)
        'vehicleManufacturer': vehicleManufacturer,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      if (vehicleYear != null) 'vehicleYear': vehicleYear,
      if (plateNumber != null) 'plateNumber': plateNumber,
      if (vin != null) 'vin': vin,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (registrationExpiry != null) 'registrationExpiry': registrationExpiry,
      if (insuranceNumber != null) 'insuranceNumber': insuranceNumber,
      if (insuranceExpiry != null) 'insuranceExpiry': insuranceExpiry,
    };
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    phoneNumber,
    profileImage,
    country,
    workingCountry,
    status,
    verificationStatus,
    rating,
    completedTrips,
    cancelledTrips,
    joinedDate,
    lastOnline,
    isOnline,
    vehicleIds,
    primaryVehicleId,
    workingAreas,
    paymentMethods,
    documents,
    statistics,
    settings,
    bio,
    languages,
    emergencyContact,
    commitmentPercentage,
    cancellationPercentage,
    totalPassengers,
    avgResponseTimeMins,
    profileImageUpdatedAt,
    passportNumber,
    passportExpiry,
    licenseNumber,
    licenseType,
    licenseCountry,
    licenseIssueDate,
    licenseExpiryDate,
    vehicleType,
    vehicleManufacturer,
    vehicleModel,
    vehicleYear,
    plateNumber,
    vin,
    registrationNumber,
    registrationExpiry,
    insuranceNumber,
    insuranceExpiry,
  ];
}
