import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminLiveTripMonitorScreen extends ConsumerWidget {
  final Map<String, dynamic>? trip;

  const AdminLiveTripMonitorScreen({super.key, this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no trip provided, we could show a list of all running trips.
    // For now, we expect a specific trip.
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المراقبة الحية')),
        body: const Center(child: Text('الرجاء اختيار رحلة للتتبع')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'تتبع حي: رحلة #${trip!['id']?.toString().substring(0, 6) ?? ''}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (trip?['isTracking'] == true)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(width: 8),
                  Text(
                    'GPS نشط',
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Simulated Map Area (2/3 of screen on desktop, full height)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blueGrey.shade100,
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 100, color: Colors.white54),
                        SizedBox(height: 16),
                        Text(
                          'سيتم عرض خريطة OpenStreetMap هنا',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.black54,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.speed, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'السرعة: ${trip!['currentSpeed'] ?? '--'} كم/س',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Side Panel (1/3 of screen)
          if (MediaQuery.of(context).size.width >= 800)
            Expanded(flex: 1, child: _buildSidePanel(trip!)),
        ],
      ),
      bottomSheet: MediaQuery.of(context).size.width < 800
          ? BottomSheet(
              onClosing: () {},
              builder: (context) =>
                  SizedBox(height: 300, child: _buildSidePanel(trip!)),
            )
          : null,
    );
  }

  Widget _buildSidePanel(Map<String, dynamic> trip) {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'معلومات الرحلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('المسار'),
            subtitle: Text(
              '${trip['departureCity']} ➔ ${trip['arrivalCity']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('السائق'),
            subtitle: Text(
              trip['driverName'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('المركبة'),
            subtitle: Text(
              trip['vehiclePlate'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'الحالة الحالية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('الوقت المقدر للوصول'),
            subtitle: Text(
              trip['eta'] ?? 'غير متوفر',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.social_distance),
            title: const Text('المسافة المتبقية'),
            subtitle: Text(
              trip['distanceRemaining'] != null
                  ? '${trip['distanceRemaining']} كم'
                  : 'غير متوفر',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.warning),
            label: const Text(
              'إطلاق إنذار طوارئ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
