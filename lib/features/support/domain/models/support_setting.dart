import 'package:equatable/equatable.dart';

class SupportSetting extends Equatable {
  final String id;
  final String contactEmail;
  final String contactPhone;
  final Map<String, dynamic> operatingHours;
  final bool liveChatEnabled;

  const SupportSetting({
    required this.id,
    required this.contactEmail,
    required this.contactPhone,
    required this.operatingHours,
    this.liveChatEnabled = true,
  });

  factory SupportSetting.fromJson(Map<String, dynamic> json, [String? docId]) {
    return SupportSetting(
      id: docId ?? json['id'] ?? 'default',
      contactEmail: json['contactEmail'] ?? 'support@rahal.com',
      contactPhone: json['contactPhone'] ?? '',
      operatingHours: Map<String, dynamic>.from(json['operatingHours'] ?? {}),
      liveChatEnabled: json['liveChatEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'operatingHours': operatingHours,
      'liveChatEnabled': liveChatEnabled,
    };
  }

  SupportSetting copyWith({
    String? id,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? operatingHours,
    bool? liveChatEnabled,
  }) {
    return SupportSetting(
      id: id ?? this.id,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      operatingHours: operatingHours ?? this.operatingHours,
      liveChatEnabled: liveChatEnabled ?? this.liveChatEnabled,
    );
  }

  @override
  List<Object?> get props => [
    id,
    contactEmail,
    contactPhone,
    operatingHours,
    liveChatEnabled,
  ];
}
