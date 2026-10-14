import 'package:equatable/equatable.dart';

class NewsModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final List<String> targetAudience;
  final DateTime createdAt;

  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.targetAudience,
    required this.createdAt,
  });

  factory NewsModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NewsModel(
      id: id,
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      targetAudience: (data['targetAudience'] as Iterable? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'targetAudience': targetAudience,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NewsModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    List<String>? targetAudience,
    DateTime? createdAt,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      targetAudience: targetAudience ?? this.targetAudience,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    imageUrl,
    targetAudience,
    createdAt,
  ];
}
