import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOperationsRepository {
  final FirebaseFirestore _firestore;

  AdminOperationsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream generic collections with filtering
  Stream<List<Map<String, dynamic>>> streamCollection(
    String collection, {
    dynamic statusFilter,
    String? statusField = 'status',
    String? searchQuery,
    String searchField = 'id',
    int limit = 100,
    String orderBy = 'createdAt',
    bool descending = true,
    bool sortLocally = false,
  }) {
    Query query = _firestore.collection(collection);

    if (statusFilter != null) {
      if (statusFilter is String && statusFilter.isNotEmpty) {
        query = query.where(statusField!, isEqualTo: statusFilter);
      } else if (statusFilter is List<String> && statusFilter.isNotEmpty) {
        query = query.where(statusField!, whereIn: statusFilter);
      }
    }

    if (!sortLocally) {
      query = query.orderBy(orderBy, descending: descending);
    }
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      var docs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (sortLocally) {
        docs.sort((a, b) {
          final aTime = _getTimestamp(a[orderBy]);
          final bTime = _getTimestamp(b[orderBy]);
          if (descending) return bTime.compareTo(aTime);
          return aTime.compareTo(bTime);
        });
      }

      // Client-side search (as simple Firestore prefix search conflicts with orderBy on different fields)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        docs = docs.where((item) {
          // Broad search across common string fields
          return item.values.any(
            (val) => val != null && val.toString().toLowerCase().contains(q),
          );
        }).toList();
      }

      return docs;
    });
  }

  // Bulk update
  Future<void> bulkUpdateStatus(
    String collection,
    List<String> ids,
    String status,
  ) async {
    final batch = _firestore.batch();
    for (var id in ids) {
      final ref = _firestore.collection(collection).doc(id);
      batch.set(ref, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final updateData = {...data, 'updatedAt': FieldValue.serverTimestamp()};
    await _firestore
        .collection(collection)
        .doc(id)
        .set(updateData, SetOptions(merge: true));
  }

  Future<int> getCount(
    String collection, {
    dynamic statusFilter,
    String? statusField = 'status',
  }) async {
    Query query = _firestore.collection(collection);
    if (statusFilter != null) {
      if (statusFilter is String && statusFilter.isNotEmpty) {
        query = query.where(statusField!, isEqualTo: statusFilter);
      } else if (statusFilter is List<String> && statusFilter.isNotEmpty) {
        query = query.where(statusField!, whereIn: statusFilter);
      }
    }
    final aggregate = await query.count().get();
    return aggregate.count ?? 0;
  }

  DateTime _getTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.now();
  }
}
