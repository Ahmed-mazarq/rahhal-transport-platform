import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;
  final String status;
  final double walletBalance;

  // Auth & Admin Approval Fields
  final String role; // passenger, driver, company, admin
  final String profileImage;
  final int? profileImageUpdatedAt;
  final bool isVerified;
  final DateTime? lastLogin;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? reviewedAt;
  final String? rejectedReason;
  final DateTime? updatedAt;
  final List<String> modificationChecklist;
  final List<Map<String, dynamic>> approvalHistory;

  // Backward compatibility getters
  String get uid => id;
  String get fullName => name;

  const UserModel({
    String? id,
    String? uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    required this.status,
    required this.walletBalance,
    this.role = 'passenger',
    this.profileImage = '',
    this.profileImageUpdatedAt,
    this.isVerified = false,
    this.lastLogin,
    this.approvedBy,
    this.approvedAt,
    this.reviewedAt,
    this.rejectedReason,
    this.updatedAt,
    this.modificationChecklist = const [],
    this.approvalHistory = const [],
  }) : id = id ?? uid ?? '';

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return UserModel(
      id: id,
      name: data['name']?.toString() ?? data['fullName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? data['hiddenEmail']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: data['status']?.toString() ?? 'active',
      walletBalance: parseDouble(data['walletBalance']),
      role: data['role']?.toString() ?? 'passenger',
      profileImage: data['profileImage']?.toString() ?? '',
      profileImageUpdatedAt: (data['profileImageUpdatedAt'] as num?)?.toInt(),
      isVerified: data['isVerified'] as bool? ?? false,
      lastLogin: data['lastLogin'] != null
          ? DateTime.tryParse(data['lastLogin'].toString())
          : null,
      approvedBy: data['approvedBy']?.toString(),
      approvedAt: data['approvedAt'] != null
          ? DateTime.tryParse(data['approvedAt'].toString())
          : null,
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.tryParse(data['reviewedAt'].toString())
          : null,
      rejectedReason: data['rejectedReason']?.toString(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
      modificationChecklist: List<String>.from(
        data['modificationChecklist'] ?? [],
      ),
      approvalHistory: List<Map<String, dynamic>>.from(
        data['approvalHistory'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'fullName': name, // Backwards compatibility for old auth usage
      'phone': phone,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'walletBalance': walletBalance,
      'role': role,
      'profileImage': profileImage,
      if (profileImageUpdatedAt != null)
        'profileImageUpdatedAt': profileImageUpdatedAt,
      'isVerified': isVerified,
      'lastLogin': lastLogin?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectedReason': rejectedReason,
      'updatedAt': updatedAt?.toIso8601String(),
      'modificationChecklist': modificationChecklist,
      'approvalHistory': approvalHistory,
    };
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? name,
    String? fullName,
    String? phone,
    String? email,
    DateTime? createdAt,
    String? status,
    double? walletBalance,
    String? role,
    String? profileImage,
    int? profileImageUpdatedAt,
    bool? isVerified,
    DateTime? lastLogin,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? reviewedAt,
    String? rejectedReason,
    DateTime? updatedAt,
    List<String>? modificationChecklist,
    List<Map<String, dynamic>>? approvalHistory,
  }) {
    return UserModel(
      id: id ?? uid ?? this.id,
      name: fullName ?? name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      profileImageUpdatedAt:
          profileImageUpdatedAt ?? this.profileImageUpdatedAt,
      isVerified: isVerified ?? this.isVerified,
      lastLogin: lastLogin ?? this.lastLogin,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      updatedAt: updatedAt ?? this.updatedAt,
      modificationChecklist:
          modificationChecklist ?? this.modificationChecklist,
      approvalHistory: approvalHistory ?? this.approvalHistory,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    createdAt,
    status,
    walletBalance,
    role,
    profileImage,
    profileImageUpdatedAt,
    isVerified,
    lastLogin,
    approvedBy,
    approvedAt,
    reviewedAt,
    rejectedReason,
    modificationChecklist,
    approvalHistory,
  ];
}
