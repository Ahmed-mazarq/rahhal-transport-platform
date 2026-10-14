import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:rahal/core/providers/repository_providers.dart';
import 'package:rahal/features/geo/domain/models/country.dart';
import 'package:rahal/features/geo/domain/models/governorate.dart';
import 'package:rahal/features/geo/domain/models/city.dart';

final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final repo = ref.watch(geoRepositoryProvider);
  final countries = await repo.getCountries();
  debugPrint('[Geo] Loaded ${countries.length} countries.');
  return countries;
});

final provincesProvider = FutureProvider.family<List<Governorate>, String>((
  ref,
  countryId,
) async {
  if (countryId.isEmpty) return [];
  debugPrint('[Geo] Loading governorates for country: $countryId');
  final repo = ref.watch(geoRepositoryProvider);
  final governorates = await repo.getGovernorates(countryId);
  debugPrint(
    '[Geo] Loaded ${governorates.length} governorates for country $countryId.',
  );
  return governorates;
});

final citiesProvider = FutureProvider.family<List<City>, String>((
  ref,
  governorateId,
) async {
  if (governorateId.isEmpty) return [];
  debugPrint('[Geo] Loading cities for governorate: $governorateId');
  final repo = ref.watch(geoRepositoryProvider);
  final cities = await repo.getCities(governorateId);
  debugPrint(
    '[Geo] Loaded ${cities.length} cities for governorate $governorateId.',
  );
  return cities;
});
