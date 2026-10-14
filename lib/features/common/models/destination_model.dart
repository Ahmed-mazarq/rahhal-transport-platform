class DestinationModel {
  final String destinationId;
  final String title;
  final String fromCity;
  final String toCity;
  final String country;
  final String imageUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DestinationModel({
    required this.destinationId,
    required this.title,
    required this.fromCity,
    required this.toCity,
    required this.country,
    required this.imageUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    return DestinationModel(
      destinationId: json['destinationId'] ?? '',
      title: json['title'] ?? '',
      fromCity: json['fromCity'] ?? '',
      toCity: json['toCity'] ?? '',
      country: json['country'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destinationId': destinationId,
      'title': title,
      'fromCity': fromCity,
      'toCity': toCity,
      'country': country,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DestinationModel copyWith({
    String? destinationId,
    String? title,
    String? fromCity,
    String? toCity,
    String? country,
    String? imageUrl,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DestinationModel(
      destinationId: destinationId ?? this.destinationId,
      title: title ?? this.title,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      country: country ?? this.country,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
