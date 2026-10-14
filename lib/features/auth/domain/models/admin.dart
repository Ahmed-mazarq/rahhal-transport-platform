import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class Admin extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // e.g. super_admin, support_admin
  final DateTime createdAt;

  const Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  Admin copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return Admin(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool validate() {
    return id.isNotEmpty && name.isNotEmpty && role.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, name, email, role, createdAt];
}
