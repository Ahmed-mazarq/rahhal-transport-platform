import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exceptions.dart';
import 'destination_service.dart';

class FirebaseDestinationService implements DestinationService {
  final FirebaseFirestore _firestore;

  FirebaseDestinationService(this._firestore);

  @override
  Future<List<Map<String, dynamic>>> getActiveDestinations({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('popular_destinations')
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['destinationId'] = doc.id;
        // Handle timestamps properly if they exist
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw FirestoreException('Firebase Error: ${e.message}');
    } catch (e) {
      throw FirestoreException('حدث خطأ غير متوقع أثناء جلب الوجهات الشائعة');
    }
  }
}
