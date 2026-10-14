import 'package:equatable/equatable.dart';
import '../../../common/utils/date_parser.dart';

class DriverFaq extends Equatable {
  final String id;
  final String title;
  final String answer;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  const DriverFaq({
    required this.id,
    required this.title,
    required this.answer,
    required this.order,
    this.isActive = true,
    required this.createdAt,
  });

  factory DriverFaq.fromJson(Map<String, dynamic> json, String id) {
    return DriverFaq(
      id: id,
      title: json['title'] ?? '',
      answer: json['answer'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateParser.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'answer': answer,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, answer, order, isActive, createdAt];
}
