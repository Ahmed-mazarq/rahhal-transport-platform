import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/models/admin_unified_document.dart';

final adminUnifiedSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final adminUnifiedRoleFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'all',
);
final adminUnifiedStatusFilterProvider = StateProvider.autoDispose<String>(
  (ref) => 'pending',
);

final adminUnifiedDocumentsStreamProvider =
    StreamProvider.autoDispose<List<AdminUnifiedDocument>>((ref) {
      final firestore = FirebaseFirestore.instance;

      // Streams
      final usersStream = firestore.collection('users').snapshots();
      final driversStream = firestore.collection('drivers').snapshots();
      final companiesStream = firestore.collection('companies').snapshots();
      final documentsStream = firestore.collection('documents').snapshots();
      final driverDocsStream = firestore
          .collection('driver_documents')
          .snapshots();
      final vehicleDocsStream = firestore
          .collection('vehicle_documents')
          .snapshots();

      return CombineLatestStream.list([
        usersStream,
        driversStream,
        companiesStream,
        documentsStream,
        driverDocsStream,
        vehicleDocsStream,
      ]).map((snapshots) {
        final usersSnap = snapshots[0];
        final driversSnap = snapshots[1];
        final companiesSnap = snapshots[2];
        final docsSnap = snapshots[3];
        final driverDocsSnap = snapshots[4];
        final vehicleDocsSnap = snapshots[5];

        final List<AdminUnifiedDocument> unifiedDocs = [];

        // Helper to get user data from users collection (often contains basic info)
        Map<String, dynamic> getUserBasic(String uid) {
          try {
            final doc = usersSnap.docs.firstWhere((d) => d.id == uid);
            return doc.data();
          } catch (_) {
            return {};
          }
        }

        String getStatus(dynamic status) {
          if (status == null) return 'pending';
          final s = status.toString().toLowerCase();
          if (s == 'accepted' || s == 'verified' || s == 'valid')
            return 'approved';
          if (s == 'declined') return 'rejected';
          return s;
        }

        // 1. Process Drivers
        for (var driverDoc in driversSnap.docs) {
          final driverData = driverDoc.data();
          final uid = driverDoc.id;
          final basicData = getUserBasic(uid);

          final ownerName =
              driverData['fullName'] ??
              basicData['fullName'] ??
              basicData['name'] ??
              'بدون اسم';
          final ownerPhone =
              driverData['phone'] ?? basicData['phone'] ?? 'بدون رقم';
          final ownerEmail = driverData['email'] ?? basicData['email'] ?? '';
          final ownerStatus =
              driverData['status'] ?? basicData['status'] ?? 'pending';

          bool hasDocuments = false;

          // Extract documents from drivers/{uid}.documents map
          if (driverData['documents'] is Map) {
            final docsMap = driverData['documents'] as Map<String, dynamic>;
            docsMap.forEach((key, val) {
              if (val is Map) {
                hasDocuments = true;
                unifiedDocs.add(
                  AdminUnifiedDocument(
                    id: 'driver_${uid}_$key',
                    ownerUid: uid,
                    ownerName: ownerName,
                    ownerPhone: ownerPhone,
                    ownerEmail: ownerEmail,
                    ownerRole: 'driver',
                    ownerStatus: ownerStatus,
                    documentKey: key,
                    documentType: key,
                    documentUrl:
                        val['url'] ?? val['fileUrl'] ?? val['photoUrl'] ?? '',
                    documentStatus: getStatus(val['status']),
                    documentNotes: val['notes'] ?? val['rejectionReason'],
                    uploadedAt: AdminUnifiedDocument.parseDate(
                      val['uploadedAt'] ?? val['createdAt'],
                    ),
                    updatedAt: AdminUnifiedDocument.parseDate(val['updatedAt']),
                    expirationDate: AdminUnifiedDocument.parseDate(
                      val['expirationDate'] ?? val['expiryDate'],
                    ),
                    sourceCollection: 'drivers',
                    sourcePath: 'drivers/$uid',
                    driverId: uid,
                    ownerData: {...basicData, ...driverData},
                    documentData: Map<String, dynamic>.from(val),
                  ),
                );
              } else if (val is String && val.isNotEmpty) {
                hasDocuments = true;
                unifiedDocs.add(
                  AdminUnifiedDocument(
                    id: 'driver_${uid}_$key',
                    ownerUid: uid,
                    ownerName: ownerName,
                    ownerPhone: ownerPhone,
                    ownerEmail: ownerEmail,
                    ownerRole: 'driver',
                    ownerStatus: ownerStatus,
                    documentKey: key,
                    documentType: key,
                    documentUrl: val,
                    documentStatus: 'pending', // Default for string-based URLs
                    sourceCollection: 'drivers',
                    sourcePath: 'drivers/$uid',
                    driverId: uid,
                    ownerData: {...basicData, ...driverData},
                    documentData: {'url': val},
                  ),
                );
              }
            });
          }

          // If no docs found, add a placeholder
          if (!hasDocuments) {
            unifiedDocs.add(
              AdminUnifiedDocument(
                id: 'driver_${uid}_none',
                ownerUid: uid,
                ownerName: ownerName,
                ownerPhone: ownerPhone,
                ownerEmail: ownerEmail,
                ownerRole: 'driver',
                ownerStatus: ownerStatus,
                documentKey: 'account_verification',
                documentType: 'بيانات الحساب',
                documentUrl: '',
                documentStatus: 'missing',
                sourceCollection: 'drivers',
                sourcePath: 'drivers/$uid',
                ownerData: {...basicData, ...driverData},
                documentData: {},
              ),
            );
          }
        }

        // 2. Process Companies
        for (var companyDoc in companiesSnap.docs) {
          final companyData = companyDoc.data();
          final uid = companyDoc.id;
          final basicData = getUserBasic(uid);

          final ownerName =
              companyData['companyName'] ??
              companyData['name'] ??
              basicData['fullName'] ??
              basicData['name'] ??
              'شركة بدون اسم';
          final ownerPhone =
              companyData['phone'] ??
              companyData['companyPhone'] ??
              basicData['phone'] ??
              'بدون رقم';
          final ownerEmail = companyData['email'] ?? basicData['email'] ?? '';
          final ownerStatus =
              companyData['status'] ?? basicData['status'] ?? 'pending';

          bool hasDocuments = false;

          if (companyData['documents'] is Map) {
            final docsMap = companyData['documents'] as Map<String, dynamic>;
            docsMap.forEach((key, val) {
              if (val is Map) {
                hasDocuments = true;
                unifiedDocs.add(
                  AdminUnifiedDocument(
                    id: 'company_${uid}_$key',
                    ownerUid: uid,
                    ownerName: ownerName,
                    ownerPhone: ownerPhone,
                    ownerEmail: ownerEmail,
                    ownerRole: 'company',
                    ownerStatus: ownerStatus,
                    documentKey: key,
                    documentType: key,
                    documentUrl:
                        val['url'] ?? val['fileUrl'] ?? val['photoUrl'] ?? '',
                    documentStatus: getStatus(val['status']),
                    documentNotes: val['notes'] ?? val['rejectionReason'],
                    uploadedAt: AdminUnifiedDocument.parseDate(
                      val['uploadedAt'] ?? val['createdAt'],
                    ),
                    updatedAt: AdminUnifiedDocument.parseDate(val['updatedAt']),
                    expirationDate: AdminUnifiedDocument.parseDate(
                      val['expirationDate'] ?? val['expiryDate'],
                    ),
                    sourceCollection: 'companies',
                    sourcePath: 'companies/$uid',
                    companyId: uid,
                    ownerData: {...basicData, ...companyData},
                    documentData: Map<String, dynamic>.from(val),
                  ),
                );
              } else if (val is String && val.isNotEmpty) {
                hasDocuments = true;
                unifiedDocs.add(
                  AdminUnifiedDocument(
                    id: 'company_${uid}_$key',
                    ownerUid: uid,
                    ownerName: ownerName,
                    ownerPhone: ownerPhone,
                    ownerEmail: ownerEmail,
                    ownerRole: 'company',
                    ownerStatus: ownerStatus,
                    documentKey: key,
                    documentType: key,
                    documentUrl: val,
                    documentStatus: 'pending', // Default for string-based URLs
                    sourceCollection: 'companies',
                    sourcePath: 'companies/$uid',
                    companyId: uid,
                    ownerData: {...basicData, ...companyData},
                    documentData: {'url': val},
                  ),
                );
              }
            });
          }

          if (!hasDocuments) {
            unifiedDocs.add(
              AdminUnifiedDocument(
                id: 'company_${uid}_none',
                ownerUid: uid,
                ownerName: ownerName,
                ownerPhone: ownerPhone,
                ownerEmail: ownerEmail,
                ownerRole: 'company',
                ownerStatus: ownerStatus,
                documentKey: 'account_verification',
                documentType: 'بيانات الشركة',
                documentUrl: '',
                documentStatus: 'missing',
                sourceCollection: 'companies',
                sourcePath: 'companies/$uid',
                ownerData: {...basicData, ...companyData},
                documentData: {},
              ),
            );
          }
        }

        // 3. Process Passengers (Users with role == passenger)
        for (var userDoc in usersSnap.docs) {
          final userData = userDoc.data();
          final role = userData['role']?.toString().toLowerCase();
          if (role == 'passenger' ||
              role == 'user' ||
              (role != 'driver' &&
                  role != 'company' &&
                  role != 'admin' &&
                  role != 'super_admin')) {
            final uid = userDoc.id;
            final ownerName =
                userData['fullName'] ?? userData['name'] ?? 'مستخدم';
            final ownerPhone = userData['phone'] ?? 'بدون رقم';
            final ownerEmail = userData['email'] ?? '';
            final ownerStatus =
                userData['status'] ?? userData['accountStatus'] ?? 'approved';

            // Passengers generally don't have nested documents in our schema.
            // If we find them in top level collections we'll merge them. But by default add an account verification entry.
            unifiedDocs.add(
              AdminUnifiedDocument(
                id: 'passenger_${uid}_none',
                ownerUid: uid,
                ownerName: ownerName,
                ownerPhone: ownerPhone,
                ownerEmail: ownerEmail,
                ownerRole: 'passenger',
                ownerStatus: ownerStatus,
                documentKey: 'account_verification',
                documentType: 'بيانات الحساب',
                documentUrl: '',
                documentStatus: 'missing',
                sourceCollection: 'users',
                sourcePath: 'users/$uid',
                ownerData: userData,
                documentData: {},
              ),
            );
          }
        }

        // Helper to merge or add top-level documents
        void mergeOrAddTopLevelDoc(
          QueryDocumentSnapshot docSnap,
          String sourceCollection,
        ) {
          final docData = docSnap.data() as Map<String, dynamic>;
          final uid =
              docData['userId'] ??
              docData['ownerId'] ??
              docData['driverId'] ??
              docData['companyId'] ??
              docData['uid'];
          if (uid == null) return;

          final key =
              docData['documentKey'] ??
              docData['documentType'] ??
              docData['type'] ??
              docSnap.id;

          // Try to find if we already have this user's data
          final basicData = getUserBasic(uid);
          final ownerName =
              docData['ownerName'] ??
              basicData['fullName'] ??
              basicData['name'] ??
              'مجهول';
          final ownerPhone =
              docData['ownerPhone'] ?? basicData['phone'] ?? 'بدون رقم';
          final ownerRole =
              docData['ownerRole'] ?? basicData['role'] ?? 'unknown';

          unifiedDocs.add(
            AdminUnifiedDocument(
              id: '${sourceCollection}_${docSnap.id}',
              ownerUid: uid,
              ownerName: ownerName,
              ownerPhone: ownerPhone,
              ownerEmail: basicData['email'] ?? '',
              ownerRole: ownerRole,
              ownerStatus: basicData['status'] ?? 'pending',
              documentKey: key,
              documentType: key,
              documentUrl:
                  docData['url'] ??
                  docData['fileUrl'] ??
                  docData['photoUrl'] ??
                  '',
              documentStatus: getStatus(docData['status']),
              documentNotes: docData['notes'] ?? docData['rejectionReason'],
              uploadedAt: AdminUnifiedDocument.parseDate(
                docData['uploadedAt'] ?? docData['createdAt'],
              ),
              updatedAt: AdminUnifiedDocument.parseDate(docData['updatedAt']),
              expirationDate: AdminUnifiedDocument.parseDate(
                docData['expirationDate'] ?? docData['expiryDate'],
              ),
              sourceCollection: sourceCollection,
              sourcePath: '$sourceCollection/${docSnap.id}',
              vehicleId: docData['vehicleId'],
              driverId: docData['driverId'],
              companyId: docData['companyId'],
              ownerData: basicData,
              documentData: docData,
            ),
          );
        }

        // 4. Process Top-level Documents
        for (var docSnap in docsSnap.docs) {
          mergeOrAddTopLevelDoc(docSnap, 'documents');
        }
        for (var docSnap in driverDocsSnap.docs) {
          mergeOrAddTopLevelDoc(docSnap, 'driver_documents');
        }
        for (var docSnap in vehicleDocsSnap.docs) {
          mergeOrAddTopLevelDoc(docSnap, 'vehicle_documents');
        }

        // 5. Deduplicate logical documents with status prioritization
        final Map<String, AdminUnifiedDocument> deduplicated = {};
        for (var doc in unifiedDocs) {
          if (doc.isMissing) {
            final key = '${doc.ownerUid}_${doc.documentKey}';
            if (!deduplicated.containsKey(key)) deduplicated[key] = doc;
            continue;
          }

          final key = '${doc.ownerUid}_${doc.documentKey}';
          if (!deduplicated.containsKey(key)) {
            deduplicated[key] = doc;
          } else {
            final existing = deduplicated[key]!;
            if (existing.isMissing) {
              deduplicated[key] = doc;
              continue;
            }

            int getWeight(String s) {
              if (s == 'approved') return 3;
              if (s == 'rejected' || s == 'needs_reupload') return 2;
              if (s == 'pending' || s == 'uploaded') return 1;
              return 0;
            }

            final wNew = getWeight(doc.documentStatus);
            final wOld = getWeight(existing.documentStatus);

            bool replace = false;
            if (wNew > wOld) {
              replace = true;
            } else if (wNew == wOld) {
              final tNew =
                  doc.updatedAt ??
                  doc.uploadedAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final tOld =
                  existing.updatedAt ??
                  existing.uploadedAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              if (tNew.isAfter(tOld)) {
                replace = true;
              }
            }

            if (replace) {
              deduplicated[key] = doc;
            }
          }
        }

        final finalDocs = deduplicated.values.toList();

        // Sort by uploadedAt descending
        finalDocs.sort((a, b) {
          final dateA = a.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.uploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        return finalDocs;
      });
    });

final filteredAdminUnifiedDocumentsProvider =
    Provider.autoDispose<List<AdminUnifiedDocument>>((ref) {
      final docsAsync = ref.watch(adminUnifiedDocumentsStreamProvider);
      final searchQuery = ref
          .watch(adminUnifiedSearchQueryProvider)
          .toLowerCase();
      final roleFilter = ref.watch(adminUnifiedRoleFilterProvider);
      final statusFilter = ref.watch(adminUnifiedStatusFilterProvider);

      return docsAsync.when(
        data: (docs) {
          return docs.where((doc) {
            // Status Match
            if (statusFilter != 'all') {
              if (statusFilter == 'missing') {
                if (!doc.isMissing) return false;
              } else if (statusFilter == 'pending') {
                if (doc.isMissing) return false;
                if (doc.documentStatus != 'pending' &&
                    doc.documentStatus != 'uploaded') {
                  return false;
                }
                if (doc.documentUrl.isEmpty) return false;
              } else {
                if (doc.isMissing) return false;
                if (doc.documentStatus != statusFilter) return false;
              }
            } else {
              // Exclude missing from 'all' view to avoid noise
              if (doc.isMissing) return false;
            }

            // Role Match
            if (roleFilter != 'all' && doc.ownerRole != roleFilter) {
              return false;
            }

            // Search Match
            if (searchQuery.isNotEmpty) {
              final matchesName = doc.ownerName.toLowerCase().contains(
                searchQuery,
              );
              final matchesPhone = doc.ownerPhone.toLowerCase().contains(
                searchQuery,
              );
              final matchesEmail = doc.ownerEmail.toLowerCase().contains(
                searchQuery,
              );
              final matchesKey = doc.documentKey.toLowerCase().contains(
                searchQuery,
              );
              final matchesUid = doc.ownerUid.toLowerCase().contains(
                searchQuery,
              );

              if (!matchesName &&
                  !matchesPhone &&
                  !matchesEmail &&
                  !matchesKey &&
                  !matchesUid) {
                return false;
              }
            }

            return true;
          }).toList();
        },
        loading: () => [],
        error: (e, st) => [],
      );
    });
