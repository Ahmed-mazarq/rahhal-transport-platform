import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isActive,
  });

  factory ServiceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceModel(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      icon: data['icon']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'isActive': isActive,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, description, icon, isActive];
}
