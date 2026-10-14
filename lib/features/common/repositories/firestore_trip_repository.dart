import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import 'trip_repository.dart';
import '../services/trip_service.dart';
import '../cache/memory_cache.dart';
import '../exceptions/app_exceptions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class FirestoreTripRepository implements TripRepository {
  final TripService _service;
  final MemoryCache<TripModel> _cache;
  final Ref _ref;

  FirestoreTripRepository(
    this._service,
    this._ref, {
    MemoryCache<TripModel>? cache,
  }) : _cache = cache ?? MemoryCache<TripModel>();

  void _checkApproval() {
    final authState = _ref.read(authProvider);
    if (authState is Authenticated) {
      final user = authState.user;
      if ((user.role == 'driver' || user.role == 'company') &&
          user.status != 'approved') {
        throw Exception(
          'لا يمكنك إجراء هذه العملية حتى يتم اعتماد حسابك من الإدارة.',
        );
      }
    }
  }

  @override
  Future<List<TripModel>> getAll({
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
  Future<TripModel?> getById(String id) async {
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
  Future<void> create(TripModel item) async {
    _checkApproval();
    try {
      await _service.save(item);
      _cache.set(item.id, item); // Maintain cache with fully updated entity
    } catch (e) {
      throw RepositoryException('Error creating $_service: $e');
    }
  }

  @override
  Future<void> update(TripModel item) async {
    _checkApproval();
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
  Stream<List<TripModel>> watchAll() {
    return _service.streamAll().handleError((e) {
      throw RepositoryException('Stream error $_service: $e');
    });
  }

  @override
  Stream<TripModel?> watchById(String id) {
    return _service.streamById(id).handleError((e) {
      throw RepositoryException('Stream error $_service: $e');
    });
  }

  @override
  Future<void> batchWrite(List<TripModel> items) async {
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

  @override
  Future<List<TripModel>> searchTrips({
    required String origin,
    required String destination,
    required DateTime travelDate,
    int passengerCount = 1,
  }) async {
    try {
      final results = await _service.searchTrips(
        origin: origin,
        destination: destination,
        travelDate: travelDate,
        passengerCount: passengerCount,
      );

      for (final item in results) {
        _cache.set(item.id, item);
      }
      return results;
    } catch (e) {
      throw RepositoryException('Error searching trips: $e');
    }
  }
}
