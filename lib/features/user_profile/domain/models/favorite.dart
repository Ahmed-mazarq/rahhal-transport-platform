import 'package:equatable/equatable.dart';

class Favorite extends Equatable {
  final String id;
  final String userId;
  final String driverId; // Favorite driver

  const Favorite({
    required this.id,
    required this.userId,
    required this.driverId,
  });

  Favorite copyWith({String? id, String? userId, String? driverId}) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
    );
  }

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'driverId': driverId};
  }

  bool validate() {
    return id.isNotEmpty && userId.isNotEmpty && driverId.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, userId, driverId];
}
