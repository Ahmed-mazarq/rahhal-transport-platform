import '../models/destination_model.dart';

abstract class DestinationRepository {
  Future<List<DestinationModel>> getActiveDestinations({int limit = 10});
}
