import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

abstract class BookingService {
  Future<List<BookingModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<BookingModel?> fetchById(String id);
  Future<void> save(BookingModel item);
  Future<void> update(BookingModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<BookingModel>> streamAll();
  Stream<BookingModel?> streamById(String id);
  Future<void> batchWrite(List<BookingModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
