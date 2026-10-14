import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rahal/core/constants/location_data.dart';
import 'logger.dart';

class DbSeeder {
  static Future<void> seedDatabase(FirebaseFirestore firestore) async {
    try {
      appLogger.i('Initializing advanced DB Seeding process...');

      final nowStr = DateTime.now().toIso8601String();

      // 1. Seed Settings if missing
      final settingsDoc = await firestore
          .collection('settings')
          .doc('default')
          .get();
      if (!settingsDoc.exists) {
        await firestore.collection('settings').doc('default').set({
          'id': 'default',
          'enableNotifications': true,
          'enableDarkMode': false,
          'baseFare': 10.0,
          'pricePerKm': 2.0,
          'activeLanguage': 'ar',
          'createdAt': nowStr,
          'updatedAt': nowStr,
          'status': 'active',
        });
        appLogger.i('Seeded default settings.');
      }

      // Check if canonical geographic data is already fully seeded
      final existingCountry = await firestore
          .collection('countries')
          .limit(1)
          .get();
      if (existingCountry.docs.isNotEmpty) {
        appLogger.i(
          'Canonical geographic data already exists. Skipping geo seed.',
        );
        return;
      }

      appLogger.i('Starting Geo Data Seeding...');

      var batch = firestore.batch();
      int operationCount = 0;

      // Define standard country IDs for canonical data
      final countryIds = {'اليمن': 'yemen', 'السعودية': 'saudi_arabia'};
      final countryCodes = {'اليمن': 'YE', 'السعودية': 'SA'};
      final countryPhoneCodes = {'اليمن': '+967', 'السعودية': '+966'};
      final countryEnNames = {'اليمن': 'Yemen', 'السعودية': 'Saudi Arabia'};

      for (var countryEntry in locationData.entries) {
        final countryNameAr = countryEntry.key;
        final countryId =
            countryIds[countryNameAr] ?? 'country_${countryNameAr.hashCode}';

        // 2. Seed Country
        final countryRef = firestore.collection('countries').doc(countryId);
        batch.set(countryRef, {
          'id': countryId,
          'nameAr': countryNameAr,
          'nameEn': countryEnNames[countryNameAr] ?? '',
          'code': countryCodes[countryNameAr] ?? '',
          'phoneCode': countryPhoneCodes[countryNameAr] ?? '',
          'createdAt': nowStr,
          'updatedAt': nowStr,
          'status': 'active',
        }, SetOptions(merge: true));
        operationCount++;

        // 3. Seed Governorates
        int govIndex = 0;
        for (var govEntry in countryEntry.value.entries) {
          final govNameAr = govEntry.key;
          final govPrefix = countryCodes[countryNameAr]?.toLowerCase() ?? 'unk';
          final govId = '${govPrefix}_gov_$govIndex';

          final govRef = firestore.collection('governorates').doc(govId);
          batch.set(govRef, {
            'id': govId,
            'countryId': countryId,
            'nameAr': govNameAr,
            'nameEn': '',
            'createdAt': nowStr,
            'updatedAt': nowStr,
            'status': 'active',
          }, SetOptions(merge: true));
          operationCount++;

          // 4. Seed Cities
          int cityIndex = 0;
          for (var cityNameAr in govEntry.value) {
            final cityId = '${govId}_city_$cityIndex';
            final cityRef = firestore.collection('cities').doc(cityId);
            batch.set(cityRef, {
              'id': cityId,
              'governorateId': govId,
              'nameAr': cityNameAr,
              'nameEn': '',
              'createdAt': nowStr,
              'updatedAt': nowStr,
              'status': 'active',
            }, SetOptions(merge: true));
            operationCount++;

            // Commit if batch is too large (Firestore limit is 500)
            if (operationCount >= 450) {
              await batch.commit();
              batch = firestore.batch();
              operationCount = 0;
            }
            cityIndex++;
          }
          govIndex++;
        }
      }

      // Commit any remaining writes
      if (operationCount > 0) {
        await batch.commit();
      }

      appLogger.i(
        'Geo Data Seeding finished successfully! (Idempotent Merge Strategy)',
      );
    } catch (e) {
      appLogger.e('Error seeding database: $e');
    }
  }
}
