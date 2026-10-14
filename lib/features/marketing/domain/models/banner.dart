import 'package:equatable/equatable.dart';

class Banner extends Equatable {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final bool isActive;

  const Banner({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.isActive = true,
  });

  Banner copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? description,
    bool? isActive,
  }) {
    return Banner(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'isActive': isActive,
    };
  }

  bool validate() {
    return id.isNotEmpty && imageUrl.isNotEmpty && title.isNotEmpty;
  }

  @override
  List<Object?> get props => [id, imageUrl, title, description, isActive];
}
