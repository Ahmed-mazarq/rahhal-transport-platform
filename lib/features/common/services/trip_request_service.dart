import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_request_model.dart';

abstract class TripRequestService {
  Future<List<TripRequestModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<TripRequestModel?> fetchById(String id);
  Future<void> save(TripRequestModel item);
  Future<void> update(TripRequestModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<TripRequestModel>> streamAll();
  Stream<TripRequestModel?> streamById(String id);
  Future<void> batchWrite(List<TripRequestModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
