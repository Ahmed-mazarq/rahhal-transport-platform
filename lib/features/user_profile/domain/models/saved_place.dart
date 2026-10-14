import 'package:equatable/equatable.dart';

class SavedPlace extends Equatable {
  final String id;
  final String userId;
  final String name; // e.g. Home, Work (in Arabic: المنزل, العمل)
  final String address;
  final double latitude;
  final double longitude;

  const SavedPlace({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  SavedPlace copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return SavedPlace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  bool validate() {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        name.isNotEmpty &&
        address.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, userId, name, address, latitude, longitude];
}
