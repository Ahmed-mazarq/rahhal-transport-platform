import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/country.dart';
import '../../domain/models/governorate.dart';
import '../../domain/models/city.dart';
import '../../domain/repositories/geo_repository.dart';

class GeoRepositoryImpl implements GeoRepository {
  final FirebaseFirestore _firestore;

  GeoRepositoryImpl(this._firestore);

  @override
  Future<List<Country>> getCountries() async {
    final snapshot = await _firestore.collection('countries').get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['id'] == null || data['id'].toString().isEmpty) {
        data['id'] = doc.id;
      }
      return Country.fromJson(data);
    }).toList();
    items.sort((a, b) => a.nameAr.compareTo(b.nameAr));
    return items;
  }

  @override
  Future<List<Governorate>> getGovernorates(String countryId) async {
    final snapshot = await _firestore
        .collection('governorates')
        .where('countryId', isEqualTo: countryId)
        .get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['id'] == null || data['id'].toString().isEmpty) {
        data['id'] = doc.id;
      }
      return Governorate.fromJson(data);
    }).toList();
    // Keep deterministic ID order or sort by name (prompt says stable order, I'll sort by ID since ID has the index 'ye_gov_0')
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  @override
  Future<List<City>> getCities(String governorateId) async {
    final snapshot = await _firestore
        .collection('cities')
        .where('governorateId', isEqualTo: governorateId)
        .get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['id'] == null || data['id'].toString().isEmpty) {
        data['id'] = doc.id;
      }
      return City.fromJson(data);
    }).toList();
    // Stable order based on ID (which contains index)
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  @override
  Future<void> saveCountry(Country country) async {
    await _firestore
        .collection('countries')
        .doc(country.id)
        .set(country.toJson());
  }

  @override
  Future<void> saveGovernorate(Governorate gov) async {
    await _firestore.collection('governorates').doc(gov.id).set(gov.toJson());
  }

  @override
  Future<void> saveCity(City city) async {
    await _firestore.collection('cities').doc(city.id).set(city.toJson());
  }
}
