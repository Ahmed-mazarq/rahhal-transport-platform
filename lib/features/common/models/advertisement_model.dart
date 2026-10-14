import 'package:equatable/equatable.dart';

class AdvertisementModel extends Equatable {
  final String id;
  final String companyId;
  final String imageUrl;
  final int clicks;
  final int impressions;
  final DateTime expiresAt;

  const AdvertisementModel({
    required this.id,
    required this.companyId,
    required this.imageUrl,
    required this.clicks,
    required this.impressions,
    required this.expiresAt,
  });

  factory AdvertisementModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return AdvertisementModel(
      id: id,
      companyId: data['companyId']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      clicks: (data['clicks'] as num?)?.toInt() ?? 0,
      impressions: (data['impressions'] as num?)?.toInt() ?? 0,
      expiresAt:
          DateTime.tryParse(data['expiresAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'imageUrl': imageUrl,
      'clicks': clicks,
      'impressions': impressions,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  AdvertisementModel copyWith({
    String? id,
    String? companyId,
    String? imageUrl,
    int? clicks,
    int? impressions,
    DateTime? expiresAt,
  }) {
    return AdvertisementModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      imageUrl: imageUrl ?? this.imageUrl,
      clicks: clicks ?? this.clicks,
      impressions: impressions ?? this.impressions,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    imageUrl,
    clicks,
    impressions,
    expiresAt,
  ];
}
