import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Company extends Equatable {
  final String id;
  final String name;
  final String logo;
  final String phoneNumber;
  final String managerName;
  final String managerPhone;
  final String country;
  final String city;
  final String address;
  final String description;
  final String website;
  final String status; // Pending Review, Approved, Suspended, Blocked
  final String verificationStatus; // verified, unverified, needs_documents
  final double rating;
  final DateTime joinedDate;

  // Stats
  final int driversCount;
  final int vehiclesCount;
  final int tripsCount;
  final int employeesCount;
  final int branchesCount;

  final List<String> operatingAreas;
  final List<String> paymentMethods;

  const Company({
    required this.id,
    required this.name,
    this.logo = '',
    required this.phoneNumber,
    required this.managerName,
    required this.managerPhone,
    required this.country,
    required this.city,
    required this.address,
    this.description = '',
    this.website = '',
    this.status = 'Pending Review',
    this.verificationStatus = 'unverified',
    this.rating = 0.0,
    required this.joinedDate,
    this.driversCount = 0,
    this.vehiclesCount = 0,
    this.tripsCount = 0,
    this.employeesCount = 0,
    this.branchesCount = 0,
    this.operatingAreas = const [],
    this.paymentMethods = const [],
  });

  Company copyWith({
    String? id,
    String? name,
    String? logo,
    String? phoneNumber,
    String? managerName,
    String? managerPhone,
    String? country,
    String? city,
    String? address,
    String? description,
    String? website,
    String? status,
    String? verificationStatus,
    double? rating,
    DateTime? joinedDate,
    int? driversCount,
    int? vehiclesCount,
    int? tripsCount,
    int? employeesCount,
    int? branchesCount,
    List<String>? operatingAreas,
    List<String>? paymentMethods,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      description: description ?? this.description,
      website: website ?? this.website,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rating: rating ?? this.rating,
      joinedDate: joinedDate ?? this.joinedDate,
      driversCount: driversCount ?? this.driversCount,
      vehiclesCount: vehiclesCount ?? this.vehiclesCount,
      tripsCount: tripsCount ?? this.tripsCount,
      employeesCount: employeesCount ?? this.employeesCount,
      branchesCount: branchesCount ?? this.branchesCount,
      operatingAreas: operatingAreas ?? this.operatingAreas,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      managerPhone: json['managerPhone'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      website: json['website'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending Review',
      verificationStatus: json['verificationStatus'] as String? ?? 'unverified',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      joinedDate: DateParser.parse(json['joinedDate']),
      driversCount: (json['driversCount'] as num?)?.toInt() ?? 0,
      vehiclesCount: (json['vehiclesCount'] as num?)?.toInt() ?? 0,
      tripsCount: (json['tripsCount'] as num?)?.toInt() ?? 0,
      employeesCount: (json['employeesCount'] as num?)?.toInt() ?? 0,
      branchesCount: (json['branchesCount'] as num?)?.toInt() ?? 0,
      operatingAreas: List<String>.from(json['operatingAreas'] ?? []),
      paymentMethods: List<String>.from(json['paymentMethods'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'phoneNumber': phoneNumber,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'country': country,
      'city': city,
      'address': address,
      'description': description,
      'website': website,
      'status': status,
      'verificationStatus': verificationStatus,
      'rating': rating,
      'joinedDate': joinedDate.toIso8601String(),
      'driversCount': driversCount,
      'vehiclesCount': vehiclesCount,
      'tripsCount': tripsCount,
      'employeesCount': employeesCount,
      'branchesCount': branchesCount,
      'operatingAreas': operatingAreas,
      'paymentMethods': paymentMethods,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    logo,
    phoneNumber,
    managerName,
    managerPhone,
    country,
    city,
    address,
    description,
    website,
    status,
    verificationStatus,
    rating,
    joinedDate,
    driversCount,
    vehiclesCount,
    tripsCount,
    employeesCount,
    branchesCount,
    operatingAreas,
    paymentMethods,
  ];
}
