import '../models/parcel_delivery.dart';
import '../models/parcel_event.dart';
import '../models/parcel_trip_match.dart';

abstract class ParcelRepository {
  Future<String> createParcelRequest(ParcelDelivery parcel);
  Future<ParcelDelivery?> getParcelDelivery(String id);
  Stream<ParcelDelivery?> watchParcelDelivery(String id);
  Future<List<ParcelDelivery>> getPassengerParcels(String passengerId);
  Future<List<ParcelDelivery>> getDriverParcels(String driverId);
  Future<List<ParcelDelivery>> getCompanyParcels(String companyId);
  Future<List<ParcelDelivery>> getMarketplaceParcels();

  Future<void> updateParcelStatus(String id, String status);
  Future<void> updateParcelPrice(String id, double price);
  Future<void> updateParcelDriver(String id, String driverId);

  Future<void> addParcelEvent(ParcelEvent event);
  Future<List<ParcelEvent>> getParcelEvents(String parcelId);
  Stream<List<ParcelEvent>> watchParcelEvents(String parcelId);

  Future<List<ParcelTripMatch>> searchEligibleTripsForParcel({
    required String originCountryId,
    String? originProvinceId,
    String? originCityId,
    required String destinationCountryId,
    String? destinationProvinceId,
    String? destinationCityId,
    required double weight,
    required String size,
  });
}
