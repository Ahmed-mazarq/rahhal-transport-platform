import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final adminCollectionStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      collectionName,
    ) {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
    });

final adminDocumentStatusUpdateProvider = Provider(
  (ref) => (String collection, String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  },
);
