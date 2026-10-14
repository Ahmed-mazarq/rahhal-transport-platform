import 'package:equatable/equatable.dart';

class BannerModel extends Equatable {
  final String id;
  final String imageUrl;
  final String linkUrl;
  final int position;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    required this.linkUrl,
    required this.position,
    required this.isActive,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BannerModel(
      id: id,
      imageUrl: data['imageUrl']?.toString() ?? '',
      linkUrl: data['linkUrl']?.toString() ?? '',
      position: (data['position'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'position': position,
      'isActive': isActive,
    };
  }

  BannerModel copyWith({
    String? id,
    String? imageUrl,
    String? linkUrl,
    int? position,
    bool? isActive,
  }) {
    return BannerModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, linkUrl, position, isActive];
}
