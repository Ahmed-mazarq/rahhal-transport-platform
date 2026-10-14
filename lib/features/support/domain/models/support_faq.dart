import 'package:equatable/equatable.dart';

class SupportFaq extends Equatable {
  final String id;
  final String category;
  final String question;
  final String answer;
  final int order;
  final bool isActive;

  const SupportFaq({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.order,
    this.isActive = true,
  });

  factory SupportFaq.fromJson(Map<String, dynamic> json, [String? docId]) {
    final String questionOrTitle =
        json['question']?.toString() ?? json['title']?.toString() ?? '';
    return SupportFaq(
      id: docId ?? json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'عام',
      question: questionOrTitle,
      answer: json['answer']?.toString() ?? '',
      order: (json['order'] is num)
          ? (json['order'] as num).toInt()
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'title': question, // Save as title too for Driver backward compatibility
      'answer': answer,
      'order': order,
      'isActive': isActive,
    };
  }

  SupportFaq copyWith({
    String? id,
    String? category,
    String? question,
    String? answer,
    int? order,
    bool? isActive,
  }) {
    return SupportFaq(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, category, question, answer, order, isActive];
}
