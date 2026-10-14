import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/admin/presentation/providers/admin_operations_provider.dart';

class AdminLiveOperationsScreen extends ConsumerWidget {
  const AdminLiveOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مركز العمليات الحية (Live Ops)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: () {}),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Live List
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن رحلة، سائق، لوحة مركبة...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final tripsAsync = ref.watch(
                          opsStreamProvider(
                            OpsCollectionParams(
                              'trips',
                              defaultStatus: ['running', 'active', 'started'],
                            ),
                          ),
                        );

                        return tripsAsync.when(
                          data: (trips) {
                            if (trips.isEmpty) {
                              return const Center(
                                child: Text(
                                  'لا توجد رحلات نشطة حالياً',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: trips.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final trip = trips[index];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    'رحلة متجهة لـ ${trip['arrivalCity'] ?? 'غير معروف'} #${trip['id']?.toString().substring(0, 6)}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'السائق: ${trip['driverName'] ?? 'غير معروف'} | الحالة: ${trip['status']}\nتاريخ الانطلاق: ${trip['departureDate'] ?? '-'}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  isThreeLine: true,
                                  onTap: () {},
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => Center(
                            child: Text(
                              'حدث خطأ: $error',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Map Area
          if (isDesktop)
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[200],
                child: Stack(
                  children: [
                    // Placeholder for Map Integration (Google Maps / Mapbox)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 120, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'تكامل الخرائط الحية (Map API Placeholder)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 24,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سيتم عرض المركبات النشطة والمسارات المرورية هنا',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floating Status Panel
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'حالة الأسطول الحالية',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildStatusRow('متصل', '245', Colors.green),
                              _buildStatusRow('في رحلة', '120', Colors.blue),
                              _buildStatusRow('غير متاح', '12', Colors.orange),
                              _buildStatusRow('تأخير مروري', '3', Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
