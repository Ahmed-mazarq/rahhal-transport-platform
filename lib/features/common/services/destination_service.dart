abstract class DestinationService {
  Future<List<Map<String, dynamic>>> getActiveDestinations({int limit = 10});
}
