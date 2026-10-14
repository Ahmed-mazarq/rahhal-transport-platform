import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_operations_provider.dart';

class AdminFleetScreen extends ConsumerStatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  ConsumerState<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends ConsumerState<AdminFleetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة الأسطول والمركبات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: const Color(0xFF0B1F3A),
          indicatorColor: const Color(0xFF0B1F3A),
          tabs: const [
            Tab(text: 'نشطة'),
            Tab(text: 'غير نشطة'),
            Tab(text: 'في الصيانة'),
            Tab(text: 'مستندات منتهية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FleetTabView(status: 'active'),
          _FleetTabView(status: 'inactive'),
          _FleetTabView(status: 'maintenance'),
          _FleetTabView(status: 'expired_docs'),
        ],
      ),
    );
  }
}

class _FleetTabView extends ConsumerWidget {
  final String status;
  const _FleetTabView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(
      opsStreamProvider(OpsCollectionParams('vehicles', defaultStatus: status)),
    );

    return streamAsync.when(
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد مركبات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return _buildDataTable(context, ref, vehicles);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) =>
                  _buildVehicleCard(context, vehicles[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> vehicles,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text(
                'المركبة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'اللوحة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'المقاعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'السائق الحالي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الشركة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'تاريخ الفحص',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الحالة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'إجراءات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: vehicles.map((v) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${v['manufacturer'] ?? ''} ${v['model'] ?? 'غير محدد'}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            v['year']?.toString() ?? '-',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    v['plate'] ?? '-',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    v['seats']?.toString() ?? '-',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    v['driverName'] ?? 'غير معين',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.blue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    v['name'] ?? '-',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    v['inspectionDate']?.toString().substring(0, 10) ?? '-',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(_buildBadge(v['status'] ?? 'active')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.green),
                        tooltip: 'تعيين سائق',
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.build, color: Colors.orange),
                        tooltip: 'صيانة',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle['manufacturer'] ?? ''} ${vehicle['model'] ?? 'غير محدد'}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'سنة الصنع: ${vehicle['year'] ?? '-'}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBadge(vehicle['status'] ?? 'active'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'اللوحة',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      vehicle['plate'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'المقاعد',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      vehicle['seats']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'السائق الحالي',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      vehicle['driverName'] ?? 'غير معين',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.build, color: Colors.orange, size: 18),
                  label: const Text(
                    'صيانة',
                    style: TextStyle(color: Colors.orange, fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F3A),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text(
                    'تعيين سائق',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'نشط';
        break;
      case 'maintenance':
        color = Colors.orange;
        label = 'في الصيانة';
        break;
      case 'expired_docs':
        color = Colors.red;
        label = 'مستندات منتهية';
        break;
      case 'inactive':
      default:
        color = Colors.grey;
        label = 'غير نشط';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
