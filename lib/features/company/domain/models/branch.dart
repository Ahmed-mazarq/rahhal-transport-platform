import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String city;
  final String address;
  final String managerName;
  final String phoneNumber;
  final String status;

  const Branch({
    required this.id,
    required this.companyId,
    required this.name,
    required this.city,
    required this.address,
    required this.managerName,
    required this.phoneNumber,
    this.status = 'active',
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'city': city,
      'address': address,
      'managerName': managerName,
      'phoneNumber': phoneNumber,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    name,
    city,
    address,
    managerName,
    phoneNumber,
    status,
  ];
}
