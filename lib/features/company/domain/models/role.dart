import 'package:equatable/equatable.dart';
import 'permission.dart';

class Role extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String description;
  final bool
  isDefault; // Cannot be deleted if true (e.g., Owner, Operations Manager)
  final List<Permission> permissions;

  const Role({
    required this.id,
    required this.companyId,
    required this.name,
    this.description = '',
    this.isDefault = false,
    this.permissions = const [],
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => Permission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'description': description,
      'isDefault': isDefault,
      'permissions': permissions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    name,
    description,
    isDefault,
    permissions,
  ];
}
