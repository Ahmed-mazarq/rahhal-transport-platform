import 'package:equatable/equatable.dart';
import 'package:rahal/features/common/models/verification_document.dart';

class CompanyModel extends Equatable {
  final String id;
  final String name;
  final String commercialRegister;
  final String status;
  final double walletBalance;
  final String ownerId;

  // Additional Registration Fields
  final String companyPhone;
  final String alternativePhone;
  final String managerName;
  final String managerPhone;
  final String managerPosition;
  final String managerNationality;
  final String managerPassportNumber;
  final String managerPassportExpiry;
  final String country;
  final String governorate;
  final String mainCity;
  final String detailedAddress;
  final String establishmentYear;
  final String businessType;
  final int branchCount;
  final int fleetSize;
  final int driverCount;
  final String companyDescription;
  final String registrationExpiry;
  final String operatingLicense;
  final String licenseExpiry;
  final String taxNumber;

  // Payment
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String iban;
  final String ewalletName;
  final String ewalletNumber;

  // Documents
  final Map<String, VerificationDocument> documents;

  // System
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.commercialRegister,
    required this.status,
    required this.walletBalance,
    required this.ownerId,
    this.companyPhone = '',
    this.alternativePhone = '',
    this.managerName = '',
    this.managerPhone = '',
    this.managerPosition = '',
    this.managerNationality = '',
    this.managerPassportNumber = '',
    this.managerPassportExpiry = '',
    this.country = '',
    this.governorate = '',
    this.mainCity = '',
    this.detailedAddress = '',
    this.establishmentYear = '',
    this.businessType = '',
    this.branchCount = 0,
    this.fleetSize = 0,
    this.driverCount = 0,
    this.companyDescription = '',
    this.registrationExpiry = '',
    this.operatingLicense = '',
    this.licenseExpiry = '',
    this.taxNumber = '',
    this.bankName = '',
    this.accountHolder = '',
    this.accountNumber = '',
    this.iban = '',
    this.ewalletName = '',
    this.ewalletNumber = '',
    this.documents = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory CompanyModel.fromFirestore(Map<String, dynamic> data, String id) {
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

    return CompanyModel(
      id: id,
      name: data['name']?.toString() ?? '',
      commercialRegister: data['commercialRegister']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      walletBalance: parseDouble(data['walletBalance']),
      ownerId: data['ownerId']?.toString() ?? '',
      companyPhone: data['companyPhone']?.toString() ?? '',
      alternativePhone: data['alternativePhone']?.toString() ?? '',
      managerName: data['managerName']?.toString() ?? '',
      managerPhone: data['managerPhone']?.toString() ?? '',
      managerPosition: data['managerPosition']?.toString() ?? '',
      managerNationality: data['managerNationality']?.toString() ?? '',
      managerPassportNumber:
          data['managerPassportNumber']?.toString() ??
          data['managerNationalId']?.toString() ??
          '',
      managerPassportExpiry: data['managerPassportExpiry']?.toString() ?? '',
      country: data['country']?.toString() ?? '',
      governorate: data['governorate']?.toString() ?? '',
      mainCity: data['mainCity']?.toString() ?? '',
      detailedAddress: data['detailedAddress']?.toString() ?? '',
      establishmentYear: data['establishmentYear']?.toString() ?? '',
      businessType: data['businessType']?.toString() ?? '',
      branchCount: parseInt(data['branchCount']),
      fleetSize: parseInt(data['fleetSize']),
      driverCount: parseInt(data['driverCount']),
      companyDescription: data['companyDescription']?.toString() ?? '',
      registrationExpiry: data['registrationExpiry']?.toString() ?? '',
      operatingLicense: data['operatingLicense']?.toString() ?? '',
      licenseExpiry: data['licenseExpiry']?.toString() ?? '',
      taxNumber: data['taxNumber']?.toString() ?? '',
      bankName: data['bankName']?.toString() ?? '',
      accountHolder: data['accountHolder']?.toString() ?? '',
      accountNumber: data['accountNumber']?.toString() ?? '',
      iban: data['iban']?.toString() ?? '',
      ewalletName: data['ewalletName']?.toString() ?? '',
      ewalletNumber: data['ewalletNumber']?.toString() ?? '',
      documents:
          (data['documents'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              VerificationDocument.fromJson(Map<String, dynamic>.from(value)),
            ),
          ) ??
          {},
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'commercialRegister': commercialRegister,
      'status': status,
      'walletBalance': walletBalance,
      'ownerId': ownerId,
      'companyPhone': companyPhone,
      'alternativePhone': alternativePhone,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'managerPosition': managerPosition,
      'managerNationality': managerNationality,
      'managerPassportNumber': managerPassportNumber,
      'managerPassportExpiry': managerPassportExpiry,
      'country': country,
      'governorate': governorate,
      'mainCity': mainCity,
      'detailedAddress': detailedAddress,
      'establishmentYear': establishmentYear,
      'businessType': businessType,
      'branchCount': branchCount,
      'fleetSize': fleetSize,
      'driverCount': driverCount,
      'companyDescription': companyDescription,
      'registrationExpiry': registrationExpiry,
      'operatingLicense': operatingLicense,
      'licenseExpiry': licenseExpiry,
      'taxNumber': taxNumber,
      'bankName': bankName,
      'accountHolder': accountHolder,
      'accountNumber': accountNumber,
      'iban': iban,
      'ewalletName': ewalletName,
      'ewalletNumber': ewalletNumber,
      'documents': documents.map((key, value) => MapEntry(key, value.toJson())),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? commercialRegister,
    String? status,
    double? walletBalance,
    String? ownerId,
    String? companyPhone,
    String? alternativePhone,
    String? managerName,
    String? managerPhone,
    String? managerPosition,
    String? managerNationality,
    String? managerPassportNumber,
    String? managerPassportExpiry,
    String? country,
    String? governorate,
    String? mainCity,
    String? detailedAddress,
    String? establishmentYear,
    String? businessType,
    int? branchCount,
    int? fleetSize,
    int? driverCount,
    String? companyDescription,
    String? registrationExpiry,
    String? operatingLicense,
    String? licenseExpiry,
    String? taxNumber,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? iban,
    String? ewalletName,
    String? ewalletNumber,
    Map<String, VerificationDocument>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      ownerId: ownerId ?? this.ownerId,
      companyPhone: companyPhone ?? this.companyPhone,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      managerPosition: managerPosition ?? this.managerPosition,
      managerNationality: managerNationality ?? this.managerNationality,
      managerPassportNumber:
          managerPassportNumber ?? this.managerPassportNumber,
      managerPassportExpiry:
          managerPassportExpiry ?? this.managerPassportExpiry,
      country: country ?? this.country,
      governorate: governorate ?? this.governorate,
      mainCity: mainCity ?? this.mainCity,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      establishmentYear: establishmentYear ?? this.establishmentYear,
      businessType: businessType ?? this.businessType,
      branchCount: branchCount ?? this.branchCount,
      fleetSize: fleetSize ?? this.fleetSize,
      driverCount: driverCount ?? this.driverCount,
      companyDescription: companyDescription ?? this.companyDescription,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      operatingLicense: operatingLicense ?? this.operatingLicense,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      taxNumber: taxNumber ?? this.taxNumber,
      bankName: bankName ?? this.bankName,
      accountHolder: accountHolder ?? this.accountHolder,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      ewalletName: ewalletName ?? this.ewalletName,
      ewalletNumber: ewalletNumber ?? this.ewalletNumber,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    commercialRegister,
    status,
    walletBalance,
    ownerId,
    companyPhone,
    alternativePhone,
    managerName,
    managerPhone,
    managerPosition,
    managerNationality,
    managerPassportNumber,
    managerPassportExpiry,
    country,
    governorate,
    mainCity,
    detailedAddress,
    establishmentYear,
    businessType,
    branchCount,
    fleetSize,
    driverCount,
    companyDescription,
    registrationExpiry,
    operatingLicense,
    licenseExpiry,
    taxNumber,
    bankName,
    accountHolder,
    accountNumber,
    iban,
    ewalletName,
    ewalletNumber,
    documents,
    createdAt,
    updatedAt,
  ];
}
