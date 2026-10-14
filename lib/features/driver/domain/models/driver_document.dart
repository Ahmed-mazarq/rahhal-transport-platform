import 'package:rahal/features/common/utils/date_parser.dart';
import 'package:equatable/equatable.dart';

class DriverDocument extends Equatable {
  final String id;
  final String
  type; // e.g. identity, driving_license, vehicle_registration, vehicle_photos
  final String documentNumber;
  final String status; // pending, approved, rejected, expired, needs_update
  final String photoUrl;
  final String localImagePath;
  final String futureStorageUrl;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String adminNotes;
  final DateTime? lastUpdated;
  final bool pendingChanges;
  final Map<String, dynamic> metadata;

  const DriverDocument({
    required this.id,
    required this.type,
    required this.documentNumber,
    this.status = 'pending',
    this.photoUrl = '',
    this.localImagePath = '',
    this.futureStorageUrl = '',
    required this.issueDate,
    required this.expiryDate,
    this.adminNotes = '',
    this.lastUpdated,
    this.pendingChanges = false,
    this.metadata = const {},
  });

  DriverDocument copyWith({
    String? id,
    String? type,
    String? documentNumber,
    String? status,
    String? photoUrl,
    String? localImagePath,
    String? futureStorageUrl,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? adminNotes,
    DateTime? lastUpdated,
    bool? pendingChanges,
    Map<String, dynamic>? metadata,
  }) {
    return DriverDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      documentNumber: documentNumber ?? this.documentNumber,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      futureStorageUrl: futureStorageUrl ?? this.futureStorageUrl,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      adminNotes: adminNotes ?? this.adminNotes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      documentNumber: json['documentNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      photoUrl: json['photoUrl'] as String? ?? '',
      localImagePath: json['localImagePath'] as String? ?? '',
      futureStorageUrl: json['futureStorageUrl'] as String? ?? '',
      issueDate: DateParser.parse(json['issueDate']),
      expiryDate: DateParser.parse(
        json['expiryDate'],
        fallback: DateTime.now().add(const Duration(days: 365)),
      ),
      adminNotes: json['adminNotes'] as String? ?? '',
      lastUpdated: json['lastUpdated'] != null
          ? DateParser.parse(json['lastUpdated'])
          : null,
      pendingChanges: json['pendingChanges'] as bool? ?? false,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'documentNumber': documentNumber,
      'status': status,
      'photoUrl': photoUrl,
      'localImagePath': localImagePath,
      'futureStorageUrl': futureStorageUrl,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'adminNotes': adminNotes,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
      'pendingChanges': pendingChanges,
      'metadata': metadata,
    };
  }

  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    documentNumber,
    status,
    photoUrl,
    localImagePath,
    futureStorageUrl,
    issueDate,
    expiryDate,
    adminNotes,
    lastUpdated,
    pendingChanges,
    metadata,
  ];
}
