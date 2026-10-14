import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';

class PassengerTrackingScreen extends ConsumerWidget {
  const PassengerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع المسار', style: TextStyle(fontFamily: 'Cairo')),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'passengerId',
                    isEqualTo: user.id,
                  ) // It might be passengerId or userId. Usually passengerId in our app.
                  .where('status', isEqualTo: 'confirmed')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد رحلة حالياً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final booking =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل الرحلة الحالية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: const Text(
                          'السائق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          booking['driverName'] ?? 'غير محدد',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                        ),
                        title: const Text(
                          'المركبة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          booking['vehicleName'] ?? 'غير محدد',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                        title: const Text(
                          'الموقع الحالي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: const Text(
                          'جاري التتبع...',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          color: Colors.blue,
                        ),
                        title: const Text(
                          'وقت الوصول المتوقع (ETA)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: const Text(
                          'يتم الحساب...',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
