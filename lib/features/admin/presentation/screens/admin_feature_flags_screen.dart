import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminFeatureFlagsScreen extends ConsumerWidget {
  const AdminFeatureFlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);

    // Default flags if not in Firestore yet
    final Map<String, String> flagDefinitions = {
      'passenger_registration': 'تسجيل الركاب الجديد',
      'driver_registration': 'تسجيل السائقين الجديد',
      'company_registration': 'تسجيل الشركات الجديد',
      'parcel_delivery': 'خدمة توصيل الطرود',
      'international_trips': 'الرحلات الدولية',
      'trip_sharing': 'مشاركة الرحلات',
      'live_tracking': 'التتبع الحي للرحلات',
      'ratings_reviews': 'التقييمات والمراجعات',
      'support_chat': 'المحادثة الفورية للدعم',
      'promotions_coupons': 'العروض والكوبونات',
      'dark_mode_client': 'الوضع الليلي للمستخدم',
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة الميزات (Feature Flags)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: flagsAsync.when(
        data: (flags) {
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: flagDefinitions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التحكم بميزات التطبيق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'يمكنك تفعيل أو إيقاف الميزات التالية مباشرة دون الحاجة لتحديث التطبيق من المتجر.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final flagKey = flagDefinitions.keys.elementAt(index - 1);
              final flagLabel = flagDefinitions[flagKey]!;
              final flagValue =
                  flags[flagKey] ?? true; // default true if not set

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: Text(
                    flagLabel,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'ID: $flagKey',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  value: flagValue,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    ref
                        .read(adminSystemRepositoryProvider)
                        .updateFeatureFlag(flagKey, val);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}
