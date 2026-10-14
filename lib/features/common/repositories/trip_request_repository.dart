import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_request_model.dart';

abstract class TripRequestRepository {
  Future<List<TripRequestModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<TripRequestModel?> getById(String id);
  Future<void> create(TripRequestModel item);
  Future<void> update(TripRequestModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<TripRequestModel>> watchAll();
  Stream<TripRequestModel?> watchById(String id);
  Future<void> batchWrite(List<TripRequestModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
