import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_history_model.dart';

abstract class BookingHistoryRepository {
  Future<List<BookingHistoryModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<BookingHistoryModel?> getById(String id);
  Future<void> create(BookingHistoryModel item);
  Future<void> update(BookingHistoryModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<BookingHistoryModel>> watchAll();
  Stream<BookingHistoryModel?> watchById(String id);
  Future<void> batchWrite(List<BookingHistoryModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
