import 'package:equatable/equatable.dart';

class GovernorateModel extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool isActive;

  const GovernorateModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.isActive,
  });

  factory GovernorateModel.fromFirestore(Map<String, dynamic> data, String id) {
    return GovernorateModel(
      id: id,
      nameAr: data['nameAr']?.toString() ?? '',
      nameEn: data['nameEn']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'nameAr': nameAr, 'nameEn': nameEn, 'isActive': isActive};
  }

  GovernorateModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    bool? isActive,
  }) {
    return GovernorateModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, isActive];
}
