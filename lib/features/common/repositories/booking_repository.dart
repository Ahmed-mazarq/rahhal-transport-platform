import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

abstract class BookingRepository {
  Future<List<BookingModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<BookingModel?> getById(String id);
  Future<void> create(BookingModel item);
  Future<void> update(BookingModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<BookingModel>> watchAll();
  Stream<BookingModel?> watchById(String id);
  Future<void> batchWrite(List<BookingModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
