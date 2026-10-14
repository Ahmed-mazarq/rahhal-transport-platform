import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_history_model.dart';

abstract class BookingHistoryService {
  Future<List<BookingHistoryModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<BookingHistoryModel?> fetchById(String id);
  Future<void> save(BookingHistoryModel item);
  Future<void> update(BookingHistoryModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<BookingHistoryModel>> streamAll();
  Stream<BookingHistoryModel?> streamById(String id);
  Future<void> batchWrite(List<BookingHistoryModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
