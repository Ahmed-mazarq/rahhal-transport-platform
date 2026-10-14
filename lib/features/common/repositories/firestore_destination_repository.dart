import '../cache/memory_cache.dart';
import '../exceptions/app_exceptions.dart';
import '../models/destination_model.dart';
import '../services/destination_service.dart';
import 'destination_repository.dart';

class FirestoreDestinationRepository implements DestinationRepository {
  final DestinationService _service;
  final MemoryCache<List<DestinationModel>> _cache;
  static const String _cacheKeyPrefix = 'destinations_active';

  FirestoreDestinationRepository(
    this._service, {
    MemoryCache<List<DestinationModel>>? cache,
  }) : _cache = cache ?? MemoryCache<List<DestinationModel>>();

  @override
  Future<List<DestinationModel>> getActiveDestinations({int limit = 10}) async {
    final cacheKey = '${_cacheKeyPrefix}_$limit';

    try {
      final cachedData = _cache.get(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final dataList = await _service.getActiveDestinations(limit: limit);
      final destinations = dataList
          .map((data) => DestinationModel.fromJson(data))
          .toList();

      _cache.set(cacheKey, destinations);
      return destinations;
    } on FirestoreException {
      throw RepositoryException('فشل في تحميل الوجهات الشائعة');
    } catch (e) {
      throw RepositoryException(
        'حدث خطأ غير متوقع أثناء تحميل الوجهات الشائعة',
      );
    }
  }
}
