import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final String id;
  final String companyId;
  final String fullName;
  final String phoneNumber;
  final String role; // 'admin', 'dispatcher', 'accountant', 'support'
  final String status; // 'active', 'inactive'
  final DateTime joinedDate;

  const Employee({
    required this.id,
    required this.companyId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.status = 'active',
    required this.joinedDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'dispatcher',
      status: json['status'] as String? ?? 'active',
      joinedDate: DateParser.parse(json['joinedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'status': status,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    fullName,
    phoneNumber,
    role,
    status,
    joinedDate,
  ];
}
