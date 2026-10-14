import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_request_model.dart';
import 'trip_request_repository.dart';
import '../services/trip_request_service.dart';
import '../cache/memory_cache.dart';
import '../exceptions/app_exceptions.dart';

class FirestoreTripRequestRepository implements TripRequestRepository {
  final TripRequestService _service;
  final MemoryCache<TripRequestModel> _cache;

  FirestoreTripRequestRepository(
    this._service, {
    MemoryCache<TripRequestModel>? cache,
  }) : _cache = cache ?? MemoryCache<TripRequestModel>();

  @override
  Future<List<TripRequestModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      final results = await _service.fetchAll(
        limit: limit,
        startAfter: startAfter,
      );
      for (final item in results) {
        _cache.set(item.id, item);
      }
      return results;
    } catch (e) {
      throw RepositoryException('Error getting all $_service: $e');
    }
  }

  @override
  Future<TripRequestModel?> getById(String id) async {
    final cached = _cache.get(id);
    if (cached != null) return cached;

    try {
      final item = await _service.fetchById(id);
      if (item != null) _cache.set(item.id, item);
      return item;
    } catch (e) {
      throw RepositoryException('Error getting by id $_service: $e');
    }
  }

  @override
  Future<void> create(TripRequestModel item) async {
    try {
      await _service.save(item);
      _cache.set(item.id, item); // Maintain cache with fully updated entity
    } catch (e) {
      throw RepositoryException('Error creating $_service: $e');
    }
  }

  @override
  Future<void> update(TripRequestModel item) async {
    try {
      await _service.update(item);
      _cache.set(item.id, item); // Maintain cache with fully updated entity
    } catch (e) {
      throw RepositoryException('Error updating $_service: $e');
    }
  }

  @override
  Future<void> delete(String id, {bool softDelete = true}) async {
    try {
      await _service.remove(id, softDelete: softDelete);
      _cache.remove(id); // Invalidate cache after deletion
    } catch (e) {
      throw RepositoryException('Error deleting $_service: $e');
    }
  }

  @override
  Stream<List<TripRequestModel>> watchAll() {
    return _service.streamAll().handleError((e) {
      throw RepositoryException('Stream error $_service: $e');
    });
  }

  @override
  Stream<TripRequestModel?> watchById(String id) {
    return _service.streamById(id).handleError((e) {
      throw RepositoryException('Stream error $_service: $e');
    });
  }

  @override
  Future<void> batchWrite(List<TripRequestModel> items) async {
    try {
      await _service.batchWrite(items);
      for (final item in items) {
        _cache.set(item.id, item); // Maintain cache
      }
    } catch (e) {
      throw RepositoryException('Error in batch write $_service: $e');
    }
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    try {
      final result = await _service.runTransaction(action);
      // Invalidate the entire cache because a transaction can alter multiple documents
      // in ways that the repository can't predict, potentially rendering the local cache stale.
      _cache.clear();
      return result;
    } catch (e) {
      throw RepositoryException('Transaction error in $_service: $e');
    }
  }
}
