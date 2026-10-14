import '../models/country.dart';
import '../models/governorate.dart';
import '../models/city.dart';

abstract class GeoRepository {
  Future<List<Country>> getCountries();
  Future<List<Governorate>> getGovernorates(String countryId);
  Future<List<City>> getCities(String governorateId);
  Future<void> saveCountry(Country country);
  Future<void> saveGovernorate(Governorate gov);
  Future<void> saveCity(City city);
}
