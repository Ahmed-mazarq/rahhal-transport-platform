import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';
import 'company_repository.dart';
import '../services/company_service.dart';
import '../cache/memory_cache.dart';
import '../exceptions/app_exceptions.dart';

class FirestoreCompanyRepository implements CompanyRepository {
  final CompanyService _service;
  final MemoryCache<CompanyModel> _cache;

  FirestoreCompanyRepository(this._service, {MemoryCache<CompanyModel>? cache})
    : _cache = cache ?? MemoryCache<CompanyModel>();

  @override
  Future<List<CompanyModel>> getAll({
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
  Future<CompanyModel?> getById(String id) async {
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
  Future<void> create(CompanyModel item) async {
    try {
      await _service.save(item);
      _cache.set(item.id, item); // Maintain cache with fully updated entity
    } catch (e) {
      throw RepositoryException('Error creating $_service: $e');
    }
  }

  @override
  Future<void> update(CompanyModel item) async {
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
  Stream<List<CompanyModel>> watchAll() {
    return _service.streamAll().handleError((e) {
      throw RepositoryException('Stream error $_service: $e');
    });
  }

  @override
  Stream<CompanyModel?> watchById(String id) {
    return _service.streamById(id).handleError((e) {
      throw RepositoryException('Stream error $_service: $e');
    });
  }

  @override
  Future<void> batchWrite(List<CompanyModel> items) async {
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
