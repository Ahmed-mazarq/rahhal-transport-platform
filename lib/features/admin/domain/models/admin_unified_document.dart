import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUnifiedDocument {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String ownerRole;
  final String ownerStatus;

  final String documentKey;
  final String documentType;
  final String documentUrl;
  final String documentStatus;
  final String? documentNotes;

  final DateTime? uploadedAt;
  final DateTime? updatedAt;
  final DateTime? expirationDate;

  final String sourceCollection;
  final String sourcePath;

  final String? vehicleId;
  final String? driverId;
  final String? companyId;

  // Entire source data for details view
  final Map<String, dynamic> ownerData;
  final Map<String, dynamic> documentData;

  AdminUnifiedDocument({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.ownerRole,
    required this.ownerStatus,
    required this.documentKey,
    required this.documentType,
    required this.documentUrl,
    required this.documentStatus,
    this.documentNotes,
    this.uploadedAt,
    this.updatedAt,
    this.expirationDate,
    required this.sourceCollection,
    required this.sourcePath,
    this.vehicleId,
    this.driverId,
    this.companyId,
    required this.ownerData,
    required this.documentData,
  });

  bool get isMissing =>
      documentStatus == 'missing' || documentStatus == 'غير متوفر';

  static DateTime? parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}
