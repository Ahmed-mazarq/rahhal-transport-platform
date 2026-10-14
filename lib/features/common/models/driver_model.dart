import 'package:equatable/equatable.dart';
import 'package:rahal/features/common/models/verification_document.dart';

class DriverModel extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String licenseNumber;
  final double rating;
  final int totalTrips;
  final bool isVerified;
  final String? companyId;

  // Section 1: Account Information
  final String nationality;
  final String gender;
  final String dateOfBirth;
  final String country;
  final String governorate;
  final String city;
  final String district;
  final String street;
  final String secondaryPhone;
  final String detailedAddress;
  final String gpsLocation;

  // Section 2: Identity Verification
  final String passportNumber;
  final String passportExpiry;
  final String passportIssueDate;
  final String passportCountry;
  final bool passportVerified;
  final String passportStatus;
  final String passportNotes;

  // Section 3: Driving License
  final String licenseType;
  final String licenseCountry;
  final String licenseIssueDate;
  final String licenseExpiryDate;

  // Section 4: Vehicle Information
  final String vehicleId;
  final String vehicleType;
  final String vehicleCategory;
  final String transmission;
  final String vehicleManufacturer;
  final String vehicleModel;
  final String vehicleYear;
  final String vehicleColor;
  final String fuelType;
  final String plateNumber;
  final String plateCountry;
  final int seatCount;
  final String vin;
  final String registrationNumber;
  final String registrationExpiry;
  final String insuranceCompany;
  final String insuranceNumber;
  final String policyNumber;
  final String insuranceExpiry;
  final String coverage;

  // Section 5: Operating Areas
  final List<String> operatingAreas;
  final List<String> operatingCities;

  // Section 6: Payment Information
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String iban;
  final String ewalletName;
  final String ewalletNumber;

  // Section 7: Emergency Contact
  final String emergencyContactName;
  final String emergencyContactRelation;
  final String emergencyContactPhone;

  // Tracking Documents (Images)
  final Map<String, VerificationDocument> documents;

  // System Fields
  final double walletBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String
  status; // pending_review, approved, rejected, need_modification, blocked, deleted
  final String driverType; // independent, company_affiliated
  final String nameOrCode;
  final bool isOnline;

  DriverModel({
    required this.id,
    required this.userId,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    required this.licenseNumber,
    required this.rating,
    required this.totalTrips,
    required this.isVerified,
    this.companyId,
    this.nationality = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.country = '',
    this.governorate = '',
    this.city = '',
    this.district = '',
    this.street = '',
    this.secondaryPhone = '',
    this.detailedAddress = '',
    this.gpsLocation = '',
    this.passportNumber = '',
    this.passportExpiry = '',
    this.passportIssueDate = '',
    this.passportCountry = '',
    this.passportVerified = false,
    this.passportStatus = 'pending',
    this.passportNotes = '',
    this.licenseType = '',
    this.licenseCountry = '',
    this.licenseIssueDate = '',
    this.licenseExpiryDate = '',
    this.vehicleId = '',
    this.vehicleType = '',
    this.vehicleCategory = '',
    this.transmission = '',
    this.vehicleManufacturer = '',
    this.vehicleModel = '',
    this.vehicleYear = '',
    this.vehicleColor = '',
    this.fuelType = '',
    this.plateNumber = '',
    this.plateCountry = '',
    this.seatCount = 0,
    this.vin = '',
    this.registrationNumber = '',
    this.registrationExpiry = '',
    this.insuranceCompany = '',
    this.insuranceNumber = '',
    this.policyNumber = '',
    this.insuranceExpiry = '',
    this.coverage = '',
    this.operatingAreas = const [],
    this.operatingCities = const [],
    this.bankName = '',
    this.accountHolder = '',
    this.accountNumber = '',
    this.iban = '',
    this.ewalletName = '',
    this.ewalletNumber = '',
    this.emergencyContactName = '',
    this.emergencyContactRelation = '',
    this.emergencyContactPhone = '',
    this.documents = const {},
    this.walletBalance = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = 'pending_review',
    this.driverType = 'independent',
    this.nameOrCode = '',
    this.isOnline = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory DriverModel.empty(String uid) {
    return DriverModel(
      id: uid,
      userId: uid,
      licenseNumber: '',
      rating: 5.0,
      totalTrips: 0,
      isVerified: false,
    );
  }

  factory DriverModel.fromFirestore(Map<String, dynamic> data, String uid) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return DriverModel(
      id: uid,
      userId: data['userId']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      licenseNumber: data['licenseNumber']?.toString() ?? '',
      rating: parseDouble(data['rating']),
      totalTrips: parseInt(data['totalTrips']),
      isVerified: data['isVerified'] as bool? ?? false,
      companyId: data['companyId']?.toString(),
      nationality: data['nationality']?.toString() ?? '',
      gender: data['gender']?.toString() ?? '',
      dateOfBirth: data['dateOfBirth']?.toString() ?? '',
      country: data['country']?.toString() ?? '',
      governorate: data['governorate']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      district: data['district']?.toString() ?? '',
      street: data['street']?.toString() ?? '',
      secondaryPhone: data['secondaryPhone']?.toString() ?? '',
      detailedAddress: data['detailedAddress']?.toString() ?? '',
      gpsLocation: data['gpsLocation']?.toString() ?? '',
      passportNumber:
          data['passportNumber']?.toString() ??
          data['nationalId']?.toString() ??
          '',
      passportExpiry:
          data['passportExpiry']?.toString() ??
          data['idExpirationDate']?.toString() ??
          '',
      passportIssueDate: data['passportIssueDate']?.toString() ?? '',
      passportCountry: data['passportCountry']?.toString() ?? '',
      passportVerified: data['passportVerified'] as bool? ?? false,
      passportStatus: data['passportStatus']?.toString() ?? 'pending',
      passportNotes: data['passportNotes']?.toString() ?? '',
      licenseType: data['licenseType']?.toString() ?? '',
      licenseCountry: data['licenseCountry']?.toString() ?? '',
      licenseIssueDate: data['licenseIssueDate']?.toString() ?? '',
      licenseExpiryDate: data['licenseExpiryDate']?.toString() ?? '',
      vehicleId: data['vehicleId']?.toString() ?? '',
      vehicleType: data['vehicleType']?.toString() ?? '',
      vehicleCategory: data['vehicleCategory']?.toString() ?? '',
      transmission: data['transmission']?.toString() ?? '',
      vehicleManufacturer: data['vehicleManufacturer']?.toString() ?? '',
      vehicleModel: data['vehicleModel']?.toString() ?? '',
      vehicleYear: data['vehicleYear']?.toString() ?? '',
      vehicleColor: data['vehicleColor']?.toString() ?? '',
      fuelType: data['fuelType']?.toString() ?? '',
      plateNumber: data['plateNumber']?.toString() ?? '',
      plateCountry: data['plateCountry']?.toString() ?? '',
      seatCount: parseInt(data['seatCount']),
      vin: data['vin']?.toString() ?? '',
      registrationNumber: data['registrationNumber']?.toString() ?? '',
      registrationExpiry: data['registrationExpiry']?.toString() ?? '',
      insuranceCompany: data['insuranceCompany']?.toString() ?? '',
      insuranceNumber: data['insuranceNumber']?.toString() ?? '',
      policyNumber: data['policyNumber']?.toString() ?? '',
      insuranceExpiry: data['insuranceExpiry']?.toString() ?? '',
      coverage: data['coverage']?.toString() ?? '',
      operatingAreas: List<String>.from(data['operatingAreas'] ?? []),
      operatingCities: List<String>.from(data['operatingCities'] ?? []),
      bankName: data['bankName']?.toString() ?? '',
      accountHolder: data['accountHolder']?.toString() ?? '',
      accountNumber: data['accountNumber']?.toString() ?? '',
      iban: data['iban']?.toString() ?? '',
      ewalletName: data['ewalletName']?.toString() ?? '',
      ewalletNumber: data['ewalletNumber']?.toString() ?? '',
      emergencyContactName: data['emergencyContactName']?.toString() ?? '',
      emergencyContactRelation:
          data['emergencyContactRelation']?.toString() ?? '',
      emergencyContactPhone: data['emergencyContactPhone']?.toString() ?? '',
      documents:
          (data['documents'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              VerificationDocument.fromJson(Map<String, dynamic>.from(value)),
            ),
          ) ??
          {},
      walletBalance: parseDouble(data['walletBalance']),
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      status: data['status']?.toString() ?? 'pending_review',
      driverType: data['driverType']?.toString() ?? 'independent',
      nameOrCode: data['nameOrCode']?.toString() ?? '',
      isOnline: data['isOnline'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'licenseNumber': licenseNumber,
      'rating': rating,
      'totalTrips': totalTrips,
      'isVerified': isVerified,
      'companyId': companyId,
      'nationality': nationality,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'country': country,
      'governorate': governorate,
      'city': city,
      'district': district,
      'street': street,
      'secondaryPhone': secondaryPhone,
      'detailedAddress': detailedAddress,
      'gpsLocation': gpsLocation,
      'passportNumber': passportNumber,
      'passportExpiry': passportExpiry,
      'passportIssueDate': passportIssueDate,
      'passportCountry': passportCountry,
      'passportVerified': passportVerified,
      'passportStatus': passportStatus,
      'passportNotes': passportNotes,
      'licenseType': licenseType,
      'licenseCountry': licenseCountry,
      'licenseIssueDate': licenseIssueDate,
      'licenseExpiryDate': licenseExpiryDate,
      'vehicleId': vehicleId,
      'vehicleType': vehicleType,
      'vehicleCategory': vehicleCategory,
      'transmission': transmission,
      'vehicleManufacturer': vehicleManufacturer,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'fuelType': fuelType,
      'plateNumber': plateNumber,
      'plateCountry': plateCountry,
      'seatCount': seatCount,
      'vin': vin,
      'registrationNumber': registrationNumber,
      'registrationExpiry': registrationExpiry,
      'insuranceCompany': insuranceCompany,
      'insuranceNumber': insuranceNumber,
      'policyNumber': policyNumber,
      'insuranceExpiry': insuranceExpiry,
      'coverage': coverage,
      'operatingAreas': operatingAreas,
      'operatingCities': operatingCities,
      'bankName': bankName,
      'accountHolder': accountHolder,
      'accountNumber': accountNumber,
      'iban': iban,
      'ewalletName': ewalletName,
      'ewalletNumber': ewalletNumber,
      'emergencyContactName': emergencyContactName,
      'emergencyContactRelation': emergencyContactRelation,
      'emergencyContactPhone': emergencyContactPhone,
      'documents': documents.map((key, value) => MapEntry(key, value.toJson())),
      'walletBalance': walletBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'driverType': driverType,
      'nameOrCode': nameOrCode,
      'isOnline': isOnline,
    };
  }

  DriverModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    String? licenseNumber,
    double? rating,
    int? totalTrips,
    bool? isVerified,
    String? companyId,
    String? nationality,
    String? gender,
    String? dateOfBirth,
    String? country,
    String? governorate,
    String? city,
    String? district,
    String? street,
    String? secondaryPhone,
    String? detailedAddress,
    String? gpsLocation,
    String? passportNumber,
    String? passportExpiry,
    String? passportIssueDate,
    String? passportCountry,
    bool? passportVerified,
    String? passportStatus,
    String? passportNotes,
    String? licenseType,
    String? licenseCountry,
    String? licenseIssueDate,
    String? licenseExpiryDate,
    String? vehicleId,
    String? vehicleType,
    String? vehicleCategory,
    String? transmission,
    String? vehicleManufacturer,
    String? vehicleModel,
    String? vehicleYear,
    String? vehicleColor,
    String? fuelType,
    String? plateNumber,
    String? plateCountry,
    int? seatCount,
    String? vin,
    String? registrationNumber,
    String? registrationExpiry,
    String? insuranceCompany,
    String? insuranceNumber,
    String? policyNumber,
    String? insuranceExpiry,
    String? coverage,
    List<String>? operatingAreas,
    List<String>? operatingCities,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? iban,
    String? ewalletName,
    String? ewalletNumber,
    String? emergencyContactName,
    String? emergencyContactRelation,
    String? emergencyContactPhone,
    Map<String, VerificationDocument>? documents,
    double? walletBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? driverType,
    String? nameOrCode,
    bool? isOnline,
  }) {
    return DriverModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      isVerified: isVerified ?? this.isVerified,
      companyId: companyId ?? this.companyId,
      nationality: nationality ?? this.nationality,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      passportIssueDate: passportIssueDate ?? this.passportIssueDate,
      passportCountry: passportCountry ?? this.passportCountry,
      passportVerified: passportVerified ?? this.passportVerified,
      passportStatus: passportStatus ?? this.passportStatus,
      passportNotes: passportNotes ?? this.passportNotes,
      licenseType: licenseType ?? this.licenseType,
      licenseCountry: licenseCountry ?? this.licenseCountry,
      licenseIssueDate: licenseIssueDate ?? this.licenseIssueDate,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      transmission: transmission ?? this.transmission,
      vehicleManufacturer: vehicleManufacturer ?? this.vehicleManufacturer,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      fuelType: fuelType ?? this.fuelType,
      plateNumber: plateNumber ?? this.plateNumber,
      plateCountry: plateCountry ?? this.plateCountry,
      seatCount: seatCount ?? this.seatCount,
      vin: vin ?? this.vin,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      policyNumber: policyNumber ?? this.policyNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      coverage: coverage ?? this.coverage,
      operatingAreas: operatingAreas ?? this.operatingAreas,
      operatingCities: operatingCities ?? this.operatingCities,
      bankName: bankName ?? this.bankName,
      accountHolder: accountHolder ?? this.accountHolder,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      ewalletName: ewalletName ?? this.ewalletName,
      ewalletNumber: ewalletNumber ?? this.ewalletNumber,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      documents: documents ?? this.documents,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      driverType: driverType ?? this.driverType,
      nameOrCode: nameOrCode ?? this.nameOrCode,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    fullName,
    phone,
    email,
    licenseNumber,
    rating,
    totalTrips,
    isVerified,
    companyId,
    nationality,
    gender,
    dateOfBirth,
    country,
    governorate,
    city,
    secondaryPhone,
    detailedAddress,
    passportNumber,
    passportExpiry,
    passportIssueDate,
    passportCountry,
    passportVerified,
    passportStatus,
    passportNotes,
    licenseType,
    licenseCountry,
    licenseIssueDate,
    licenseExpiryDate,
    vehicleId,
    vehicleType,
    vehicleManufacturer,
    vehicleModel,
    vehicleYear,
    vehicleColor,
    fuelType,
    plateNumber,
    plateCountry,
    seatCount,
    vin,
    registrationNumber,
    registrationExpiry,
    insuranceNumber,
    insuranceExpiry,
    operatingAreas,
    operatingCities,
    bankName,
    accountHolder,
    accountNumber,
    iban,
    ewalletName,
    ewalletNumber,
    emergencyContactName,
    emergencyContactRelation,
    emergencyContactPhone,
    documents,
    walletBalance,
    createdAt,
    updatedAt,
    status,
    driverType,
    nameOrCode,
    isOnline,
  ];
}
