import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/governorate_model.dart';
import 'governorate_service.dart';
import '../exceptions/app_exceptions.dart';

class FirebaseGovernorateService implements GovernorateService {
  final FirebaseFirestore _firestore;
  final String _collection = 'governorates';

  FirebaseGovernorateService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<GovernorateModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      CollectionReference<Map<String, dynamic>> ref = _firestore.collection(
        _collection,
      );
      Query<Map<String, dynamic>> query = ref.where(
        'isDeleted',
        isNotEqualTo: true,
      );
      if (limit != null) query = query.limit(limit);
      if (startAfter != null) query = query.startAfterDocument(startAfter);

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      return snapshot.docs
          .map((doc) => GovernorateModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to fetch $_collection: $e');
    }
  }

  @override
  Future<GovernorateModel?> fetchById(String id) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef = _firestore
          .collection(_collection)
          .doc(id);
      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['isDeleted'] == true) return null;
      return GovernorateModel.fromFirestore(data, doc.id);
    } catch (e) {
      throw FirestoreException('Failed to fetch by id in $_collection: $e');
    }
  }

  @override
  Future<void> save(GovernorateModel item) async {
    try {
      final data = item.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      DocumentReference<Map<String, dynamic>> docRef = _firestore
          .collection(_collection)
          .doc(item.id);
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException('Failed to save in $_collection: $e');
    }
  }

  @override
  Future<void> update(GovernorateModel item) async {
    try {
      final data = item.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();
      DocumentReference<Map<String, dynamic>> docRef = _firestore
          .collection(_collection)
          .doc(item.id);
      await docRef.update(data);
    } catch (e) {
      throw FirestoreException('Failed to update in $_collection: $e');
    }
  }

  @override
  Future<void> remove(String id, {bool softDelete = true}) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef = _firestore
          .collection(_collection)
          .doc(id);
      if (softDelete) {
        await docRef.update({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.delete();
      }
    } catch (e) {
      throw FirestoreException('Failed to delete in $_collection: $e');
    }
  }

  @override
  Stream<List<GovernorateModel>> streamAll() {
    CollectionReference<Map<String, dynamic>> ref = _firestore.collection(
      _collection,
    );
    return ref
        .where('isDeleted', isNotEqualTo: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((doc) => GovernorateModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<GovernorateModel?> streamById(String id) {
    DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection(_collection)
        .doc(id);
    return docRef.snapshots().map((DocumentSnapshot<Map<String, dynamic>> doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['isDeleted'] == true) return null;
      return GovernorateModel.fromFirestore(data, doc.id);
    });
  }

  @override
  Future<void> batchWrite(List<GovernorateModel> items) async {
    try {
      final WriteBatch batch = _firestore.batch();
      for (final item in items) {
        DocumentReference<Map<String, dynamic>> docRef = _firestore
            .collection(_collection)
            .doc(item.id);
        batch.set(docRef, item.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      throw FirestoreException('Failed batch write in $_collection: $e');
    }
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    try {
      return await _firestore.runTransaction(action);
    } catch (e) {
      throw FirestoreException('Transaction failed in $_collection: $e');
    }
  }
}
